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
// Engineer:       Francesco Conti - f.conti@unibo.it
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

module register_allocation_table #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg       = config_pkg::cva6_cfg_empty,
    parameter int unsigned           DATA_WIDTH    = 32,
    parameter int unsigned           NR_READ_PORTS = 2,
    parameter int unsigned           ADDR_WIDTH    = 5;
) (
    input  logic                                         rst_ni,
    input  logic [CVA6Cfg.NrIssuePorts-1:0]              we_i,
    input  scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_i,
    output scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0] renamed_instr_o,
);

  localparam NUM_WORDS = 2 ** ADDR_WIDTH;
  localparam LOG_NR_WRITE_PORTS = CVA6Cfg.NrCommitPorts == 1 ? 1 : $clog2(CVA6Cfg.NrCommitPorts);

  localparam NUM_REG = 2 ** ADDR_WIDTH;

  //Next writable register
  logic [NUM_REG-1:0] renaming_pointer;
  // RAT of size nb register i.e 32 containing adress of physical register
  logic [ADDR_WIDTH-1:0] rat[31:0];

  always_comb begin : renaming_dest
    if (rst_ni == 1'b0) begin
      renaming_pointer = '0;
    end
  end

  //renames the dest reg
  always_comb begin : renaming_dest
    for (int unsigned i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
      if we_i[i] begin
        decoded_instr_i[i].rs1 = rat[decoded_instr_i[i].rs1];
        decoded_instr_i[i].rs2 = rat[decoded_instr_i[i].rs2];
        //if result is used as third operand we also rename it
        if (NR_READ_PORTS == 3 && decoded_instr_i[i].use_imm == 1'b0) begin
          decoded_instr_i[i].result = rat[decoded_instr_i[i].result];
        end
        rat[decoded_instr_i[i].rd]= renaming_pointer;
        decoded_instr_i[i].rd = renaming_pointer;
        renaming_pointer = renaming_pointer + 1;
      end
    end
  end

  renamed_instr_o <= decoded_instr_i;

endmodule
