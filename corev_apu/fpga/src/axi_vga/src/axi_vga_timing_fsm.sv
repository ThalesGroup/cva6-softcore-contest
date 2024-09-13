// Simple VGA IP capable of drawing frames from an external framebuffer.

// Description: Set timing VGA
// Author: Abdou Lahat NDIAYE <abdou-lahat.ndiaye@thalesgroup.com>


module axi_vga_timing_fsm #(
  parameter int unsigned HCountWidth  = 32,
  parameter int unsigned VCountWidth  = 32
)(
  input logic                     pxl_clk,
  input logic                     rst_ni,

  input logic                     fsm_en_i,
  input wire axi_vga_reg_pkg::axi_vga_reg2hw_t reg2hw_i,

  output logic                    visible,

  // VGA output
  output logic                    hsync_o,
  output logic                    vsync_o

);
  typedef enum logic [1:0] {VISIBLE, FRONT_PORCH, SYNC, BACK_PORCH} axi_vga_state_t;

  logic [HCountWidth-1:0] hcounter_q, hcounter_d;
  logic [VCountWidth-1:0] vcounter_q, vcounter_d;

  axi_vga_state_t hstate_q, hstate_d, vstate_q, vstate_d;


  logic fsm_en;

  logic [31:0] h_visible_size, h_front_size, h_sync_size, h_back_size;
  logic [31:0] v_visible_size, v_front_size, v_sync_size, v_back_size;

  // Static assignments
 /* assign red_o    = (visible & valid_i) ? red_i : 'b0;
  assign green_o  = (visible & valid_i) ? green_i : 'b0;
  assign blue_o   = (visible & valid_i) ? blue_i :'b0;*/
  assign hsync_o  = reg2hw_i.control.hsync_pol.q ? hstate_q == SYNC : ~(hstate_q == SYNC);
  assign vsync_o  = reg2hw_i.control.vsync_pol.q ? vstate_q == SYNC : ~(vstate_q == SYNC);

  assign visible = (hstate_q == VISIBLE) & (vstate_q == VISIBLE);
  assign ready_o = visible & fsm_en;
//assign fifo_ready_o = (hstate_q == BACK_PORCH) & (vstate_q == VISIBLE) & fsm_en;

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
            hcounter_d  = h_visible_size;
            hstate_d    = VISIBLE;
          end
        end

        default: begin
          hstate_d = VISIBLE;
        end
      endcase
    end else if (!reg2hw_i.control.enable.q) begin
      hcounter_d = h_back_size;
      hstate_d   = BACK_PORCH;
    end
  end

  // Vertical FSM
  always_comb begin
    vstate_d    = vstate_q;
    vcounter_d  = vcounter_q;

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
  always_ff @(posedge pxl_clk, negedge rst_ni) begin
    if(!rst_ni) begin
      hcounter_q  <= 'd1;
      vcounter_q  <= 'd1;
      hstate_q    <= BACK_PORCH;
      vstate_q    <= BACK_PORCH;
    end else begin
      hcounter_q  <= hcounter_d;
      vcounter_q  <= vcounter_d;
      hstate_q    <= hstate_d;
      vstate_q    <= vstate_d;
    end
  end

endmodule

