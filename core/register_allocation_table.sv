// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright 2024 - PlanV Technologies for additionnal contribution.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Engineer:       Fieux Telmo - fieuxtelmo@gmail.com
//
// Additional contributions by:
//                 Markus Wegmann - markus.wegmann@technokrat.ch
//                 Noam Gallmann - gnoam@live.com
//                 Felipe Lisboa Malaquias
//                 Henry Suzukawa
//                 Angela Gonzalez - PlanV Technologies
//
// Description:    This register file is optimized for implementation on
//                 FPGAs. The register file features one distributed RAM block per implemented
//                 sync-write port, each with a parametrized number of async-read ports.
//                 Read-accesses are multiplexed from the relevant block depending on which block
//                 was last written to. For that purpose an additional array of registers is
//                 maintained keeping track of write acesses.
//

module register_allocation_table
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg       = config_pkg::cva6_cfg_empty,
    parameter int unsigned           DATA_WIDTH    = 32,
    parameter int unsigned           NR_READ_PORTS = 2,
    parameter int unsigned           ADDR_WIDTH    = 5,
    parameter logic                  COMMIT_RAT    = 1'b0, //0 for issue_rat 1 for commit_rat
    parameter logic                  FPR_RAT       = 1'b0, //0 for if gpr rat else 1
    parameter type scoreboard_entry_t = logic
) (
    input logic                                               clk_i,
    input logic                                               rst_ni,
    input logic [CVA6Cfg.NrIssuePorts-1:0]                    we_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0]                    commit_valid_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0][ADDR_WIDTH-1:0]    commit_rd_i,
    input fu_op [CVA6Cfg.NrIssuePorts-1:0]                    commit_op_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0][ADDR_WIDTH-1:0]    commit_old_phys_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0][ADDR_WIDTH-1:0]    commit_new_phys_i,
    input logic [ADDR_WIDTH-1:0]                              rollback_rd_i, // architectural register to rollback
    input logic [ADDR_WIDTH-1:0]                              rollback_old_phys_i, // architectural register to rollback
    input logic                                               rollback_we_i, // rollback is enabled

    input  scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_i, //May be unnecessary to pass the entirety of the struct scoreboard_entry_t
    input  logic              [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_ack_i,
    output scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0] renamed_instr_o,

    output rat_table_t                  rat_state_o,
    input  rat_table_t                  rat_restore_state_i,
    input  logic                        rat_restore_en_i

);
  localparam NUM_REG = 2 ** ADDR_WIDTH;

  //keeps track of free physical registers
  logic [NUM_REG-1:0] free_regs_masked [CVA6Cfg.NrIssuePorts:0];
  logic [ADDR_WIDTH-1:0] alloc_idx     [CVA6Cfg.NrIssuePorts-1:0];

  assign free_regs_masked[0] = rat_q.free_regs;

  //priority encoder cascade to get index for each instr
  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin : g_alloc
      lzc #(
          .WIDTH(NUM_REG),
          .MODE(1'b0))
      i_lzc (
          .in_i   (free_regs_masked[i]),
          .cnt_o  (alloc_idx[i]),
          .empty_o()
      );

      assign free_regs_masked[i+1] = (we_i[i] && decoded_instr_ack_i[i] && (decoded_instr_i[i].rd != '0)) ?
        (free_regs_masked[i] & ~(NUM_REG'(1) << alloc_idx[i])) :
        free_regs_masked[i];
  end

  // RAT of size nb register i.e 32 containing adress of physical register
  rat_table_t rat_n, rat_q;

  always_comb begin : renaming
    rat_n = rat_q;

    for (int i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
      renamed_instr_o[i] = decoded_instr_i[i];
      renamed_instr_o[i].arch_rd = decoded_instr_i[i].rd;

      // Renaming destination
      if (we_i[i] && decoded_instr_ack_i[i] && (decoded_instr_i[i].rd != '0)) begin
        renamed_instr_o[i].old_phys = rat_q.rat[decoded_instr_i[i].rd];
        renamed_instr_o[i].rd          = alloc_idx[i];
      end else begin
        renamed_instr_o[i].old_phys = decoded_instr_i[i].rd;
      end

      // Renaming sources
      renamed_instr_o[i].rs1 = rat_q.rat[decoded_instr_i[i].rs1];
      renamed_instr_o[i].rs2 = rat_q.rat[decoded_instr_i[i].rs2];
      if (NR_READ_PORTS == 3 && !decoded_instr_i[i].use_imm) begin
        renamed_instr_o[i].result = rat_q.rat[decoded_instr_i[i].result];
      end
    end

    //updating free list after commit
    if (!rat_restore_en_i) begin
      rat_n.free_regs = free_regs_masked[CVA6Cfg.NrIssuePorts];
      for (int i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
        if (commit_valid_i[i] && ((is_rd_fpr(commit_op_i) && FPR_RAT==1'b1) || (!is_rd_fpr(commit_op_i) && FPR_RAT==1'b0))) begin
          rat_n.free_regs[commit_old_phys_i[i]] = 1'b1; //freeing old reg
          //locking new reg. Useless for issue rat but necessary for commit rat
          rat_n.free_regs[commit_new_phys_i[i]] = 1'b0;
          if (COMMIT_RAT == 1'b1 && commit_rd_i[i] != '0) begin
            rat_n.rat[commit_rd_i[i]] = commit_new_phys_i[i];
          end
        end


      end
      for (int i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
        if (we_i[i] && decoded_instr_ack_i[i] && (decoded_instr_i[i].rd != '0)) begin
          rat_n.rat[decoded_instr_i[i].rd] = alloc_idx[i];
        end
      end
    end

    //rollback
    if(rollback_we_i) begin
      rat_n.free_regs[rat_n.rat[rollback_rd_i]] = 1'b1;
      rat_n.rat[rollback_rd_i] = rollback_old_phys_i;
    end

    if (rat_restore_en_i) begin
      rat_n = rat_restore_state_i;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rat_q.free_regs <= NUM_REG'('1) << 32;
      for (int i = 0; i < 32; i++) begin
        rat_q.rat[i] <= ADDR_WIDTH'(i);
      end
    end else begin
      rat_q <= rat_n;
      rat_state_o <= rat_n;
    end
  end
endmodule
