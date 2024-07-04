// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

// Simple VGA IP capable of drawing frames from an external framebuffer

module axi_vga_timing_fsm #(
  parameter int unsigned RedWidth     = 5,
  parameter int unsigned GreenWidth   = 6,
  parameter int unsigned BlueWidth    = 5,
  parameter int unsigned HCountWidth  = 800,
  parameter int unsigned VCountWidth  = 600
)(
  input logic                     clk_i,
  input logic                     rst_ni,

  input logic                     fsm_en_i,
  input wire axi_vga_reg_pkg::axi_vga_reg2hw_t reg2hw_i,

  // Data input
  input logic  [RedWidth-1:0]     red_i,
  input logic  [GreenWidth-1:0]   green_i,
  input logic  [BlueWidth-1:0]    blue_i,
  input logic                     valid_i,
  output logic                    ready_o,
  output logic fifo_ready_o,
  output logic             start_sync ,

  // VGA output
  output logic                    hsync_o,
  output logic                    vsync_o,
  output logic [RedWidth-1:0]     red_o,
  output logic [GreenWidth-1:0]   green_o,
  output logic [BlueWidth-1:0]    blue_o
);
  typedef enum logic [2:0] {VISIBLE, FRONT_PORCH, SYNC, BACK_PORCH, OFFSET} axi_vga_state_t;
  typedef enum logic [1:0] {VISIBLE_REQ, IDLE} synchro_vga_state_t;
  logic [HCountWidth-1:0] hcounter_q, hcounter_d, scounter_q, scounter_d, vscounter_q, vscounter_d, h_offset;
  logic [VCountWidth-1:0] vcounter_q, vcounter_d;

  axi_vga_state_t hstate_q, hstate_d, vstate_q, vstate_d;
synchro_vga_state_t synchro_state_q,  synchro_state_d, vsynchro_state_q,  vsynchro_state_d;
  logic visible, visible_synchro;

  logic fsm_en;

  logic [31:0] h_visible_size, h_front_size, h_sync_size, h_back_size;
  logic [31:0] v_visible_size, v_front_size, v_sync_size, v_back_size;

  // Static assignments
  assign red_o    = (visible ) ? red_i : 'b0;
  assign green_o  = (visible ) ? green_i : 'b0;
  assign blue_o   = (visible ) ? blue_i :'b0;
  assign hsync_o  = reg2hw_i.control.hsync_pol.q | (hstate_q==OFFSET) ? hstate_q == SYNC : ~(hstate_q == SYNC);
  assign vsync_o  = reg2hw_i.control.vsync_pol.q | (hstate_q==OFFSET) ? vstate_q == SYNC : ~(vstate_q == SYNC);

  assign visible_synchro = (synchro_state_q == VISIBLE_REQ) & (vsynchro_state_q == VISIBLE_REQ);
    assign visible = (hstate_q == VISIBLE) & (vstate_q == VISIBLE);

  assign ready_o = visible_synchro & fsm_en;
assign fifo_ready_o = visible & fsm_en;

  // Enable FSM only if external enable is high (fsm_en_i) and enable register
  // is set too (reg2hw_i.control.q)
  assign fsm_en = reg2hw_i.control.enable.q & fsm_en_i;

  assign h_visible_size = reg2hw_i.hori_visible_size.q;
  assign h_front_size   = reg2hw_i.hori_front_porch_size.q;
  assign h_sync_size    = reg2hw_i.hori_sync_size.q;
  assign h_back_size    = reg2hw_i.hori_back_porch_size.q;

  assign v_visible_size = reg2hw_i.vert_visible_size.q;
  assign v_front_size   = reg2hw_i.vert_front_porch_size.q;
  assign v_sync_size    = reg2hw_i.vert_sync_size.q;
  assign v_back_size    = reg2hw_i.vert_back_porch_size.q;
  assign h_offset	 = reg2hw_i.offset.q; //32'h20;

// Horizontal synchro FSM
  always_comb begin
    scounter_d  = scounter_q;
    synchro_state_d    = synchro_state_q;

    if (fsm_en) begin
      scounter_d  = scounter_q - 1;

      unique case (synchro_state_q)
        VISIBLE_REQ: begin
          if (scounter_q == 1) begin
            scounter_d = h_front_size + h_sync_size + h_back_size;
            synchro_state_d = IDLE;
          end
        end

        IDLE: begin
          if (scounter_q == 1) begin
            scounter_d = h_visible_size;
            synchro_state_d = VISIBLE_REQ;
          end
        end
        default: begin
          synchro_state_d = VISIBLE_REQ;
        end
        endcase
end else if (!reg2hw_i.control.enable.q) begin
      scounter_d = 1;
      synchro_state_d = IDLE;
    end
    end
    
// Vertical synchro FSM
  always_comb begin
    vscounter_d  = vscounter_q;
    vsynchro_state_d    = vsynchro_state_q;


    if (fsm_en && synchro_state_q == IDLE && scounter_q == 1) begin
      vscounter_d  = vscounter_q - 1;


      unique case (vsynchro_state_q)
        VISIBLE_REQ: begin
          if (vscounter_q == 1) begin
            vscounter_d = v_front_size + v_sync_size + v_back_size;
            vsynchro_state_d = IDLE;

          end
        end

        IDLE: begin
          if (vscounter_q == 1) begin
            vscounter_d = v_visible_size;
            vsynchro_state_d = VISIBLE_REQ;
          end
        end
        default: begin
          vsynchro_state_d = VISIBLE_REQ;
        end
        endcase
end else if (!reg2hw_i.control.enable.q) begin
      vscounter_d = 1;
      vsynchro_state_d = IDLE;
    end
    end
    
    
  // Horizontal FSM
  always_comb begin
    hcounter_d  = hcounter_q;
    hstate_d    = hstate_q;


    if (fsm_en) begin
      hcounter_d  = hcounter_q - 1;
	
      unique case (hstate_q)
        VISIBLE: begin
          if (hcounter_q == 1) begin
            hcounter_d = h_front_size;
            hstate_d = FRONT_PORCH;
          end
        end

        FRONT_PORCH: begin
          if (hcounter_q == 1) begin
            hcounter_d = h_sync_size;
            hstate_d = SYNC;
          end
        end

        SYNC: begin
          if (hcounter_q == 1) begin
            hcounter_d = h_back_size;
            hstate_d = BACK_PORCH;
          end
        end

        BACK_PORCH: begin
          if (hcounter_q == 1) begin
            hcounter_d  = h_visible_size ;
            hstate_d    = VISIBLE;
          end
        end

OFFSET: begin
          if (hcounter_q == 1) begin
            hcounter_d  = 1;
            hstate_d    = BACK_PORCH;
          end
        end
        default: begin
          hstate_d = OFFSET;
          hcounter_d  = h_offset;
        end
      endcase
    end else if (!reg2hw_i.control.enable.q) begin
      hcounter_d  = h_offset;
      hstate_d   = OFFSET;
    end
  end

  // Vertical FSM
  always_comb begin
    vstate_d    = vstate_q;
    vcounter_d  = vcounter_q;
                start_sync = 1'b0;

    if (fsm_en && hstate_q == BACK_PORCH && hcounter_q == 1) begin
      vcounter_d  = vcounter_q - 1;

      unique case (vstate_q)
        VISIBLE: begin
          if (vcounter_q == 1) begin
            vcounter_d = v_front_size;
            vstate_d = FRONT_PORCH;
          end
        end

        FRONT_PORCH: begin
          if (vcounter_q == 1) begin
            vcounter_d = v_sync_size;
            vstate_d = SYNC;
            start_sync = 1'b1;
          end
        end

        SYNC: begin
          if (vcounter_q == 1) begin
            vcounter_d = v_back_size;
            vstate_d = BACK_PORCH;
          end
        end

        BACK_PORCH: begin
          if (vcounter_q == 1) begin
            vcounter_d  = v_visible_size;
            vstate_d    = VISIBLE;
          end
        end


        default: begin
          vstate_d = VISIBLE;
        end
      endcase
    end else if (!reg2hw_i.control.enable.q) begin
      vcounter_d = 1;
      vstate_d   = BACK_PORCH;
    end
  end

  // Flip-Flops
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(!rst_ni) begin
      hcounter_q  <= 'd1;
      vcounter_q  <= 'd1;
      hstate_q    <= OFFSET;
      vstate_q    <= BACK_PORCH;
      
      scounter_q  <= 'd1;
      synchro_state_q <= IDLE;
      vscounter_q  <= 'd1;
      vsynchro_state_q <= IDLE;
    end else begin
      hcounter_q  <= hcounter_d;
      vcounter_q  <= vcounter_d;
      hstate_q    <= hstate_d;
      vstate_q    <= vstate_d;
       
      scounter_q  <= scounter_d;     
      synchro_state_q <= synchro_state_d;
      vscounter_q  <= vscounter_d;     
      vsynchro_state_q <= vsynchro_state_d;
    end
  end

endmodule
