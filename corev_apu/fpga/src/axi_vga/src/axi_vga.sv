// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

// Simple VGA IP capable of drawing frames from an external framebuffer.

module axi_vga #(
  parameter int unsigned RedWidth     = 5,
  parameter int unsigned GreenWidth   = 6,
  parameter int unsigned BlueWidth    = 5,
  parameter int unsigned HCountWidth  = 32,
  parameter int unsigned VCountWidth  = 32,
  parameter int unsigned AXIAddrWidth = 64,
  parameter int unsigned AXIDataWidth = 64,
  parameter int unsigned AXIStrbWidth = 8 ,
  parameter type axi_req_t            = logic,
  parameter type axi_resp_t           = logic,
  parameter type reg_req_t            = logic,
  parameter type reg_rsp_t           = logic
)(
  input logic                     clk_i, pxl_clk,
  input logic                     rst_ni,

  input logic                     test_mode_en_i,

  // Regbus config ports
  input  reg_req_t                reg_req_i,
  output reg_rsp_t               reg_rsp_o,

  // AXI Data ports
  output axi_req_t                axi_req_o,
  input  axi_resp_t               axi_resp_i,

  // VGA interface
  output logic                    hsync_o,
  output logic                    vsync_o,
  output logic [RedWidth-1:0]     red_o,
  output logic [GreenWidth-1:0]   green_o,
  output logic [BlueWidth-1:0]    blue_o
);

  logic [7:0] clk_div;
  logic [7:0] clk_cnt_d, clk_cnt_q;

  axi_vga_reg_pkg::axi_vga_reg2hw_t reg2hw;

  logic [RedWidth-1:0]   red;
  logic [GreenWidth-1:0] green;
  logic [BlueWidth-1:0]  blue;
  logic valid, ready, fifo_ready,    start_sync ;

  // Clock divider constant
  assign clk_div = |reg2hw.clk_div.q ? reg2hw.clk_div.q : 1;

  // Cycle counter to scale the incoming clock
  assign clk_cnt_d = (clk_cnt_q < (clk_div-1)) ? clk_cnt_q + 8'b0000_0001 : 8'b0;
logic pxl_clk_i;
//assign pxl_clk_i = |reg2hw.fifo_depth.q ? pxl_clk : clk_i;

  // Regbus register interface
  axi_vga_reg_top #(
    .reg_req_t      ( reg_req_t           ),
    .reg_rsp_t      ( reg_rsp_t          ),
    .AW             ( 7                   )
  ) i_axi_vga_register_file (
    .clk_i,
    .rst_ni,
    .reg_req_i,
    .reg_rsp_o,
    // To HW
    .reg2hw         ( reg2hw              ), // Write
    // Config
    .devmode_i      ( '1                  )  // Explicit error for unmapped register access
  );

  // FSM managing the VGA signals
  axi_vga_timing_fsm #(
    .RedWidth       ( RedWidth            ),
    .GreenWidth     ( GreenWidth          ),
    .BlueWidth      ( BlueWidth           ),
    .HCountWidth    ( HCountWidth         ),
    .VCountWidth    ( VCountWidth         )
  ) i_axi_vga_timing_fsm (
    .clk_i(clk_i),
    .rst_ni,

    .fsm_en_i       ( clk_cnt_q == 0      ),
    .reg2hw_i       ( reg2hw              ),

    // Data input
    .red_i          ( red                 ),
    .green_i        ( green               ),
    .blue_i         ( blue                ),
    .valid_i        ( valid               ),
    .ready_o        ( ready               ),
    .fifo_ready_o        ( fifo_ready               ),
        .start_sync ,

    // VGA interface
    .hsync_o,
    .vsync_o,
    .red_o,
    .green_o,
    .blue_o
  );

  axi_vga_fetcher #(
    .RedWidth       ( RedWidth            ),
    .GreenWidth     ( GreenWidth          ),
    .BlueWidth      ( BlueWidth           ),
    .AXIAddrWidth   ( AXIAddrWidth        ),
    .AXIDataWidth   ( AXIDataWidth        ),
    .AXIStrbWidth   ( AXIStrbWidth        ),
    .axi_req_t      ( axi_req_t           ),
    .axi_resp_t     ( axi_resp_t          )
  ) i_axi_vga_fetcher (
    .clk_i,
    .pxl_clk(clk_i),
    .rst_ni,
    .enable_i       ( reg2hw.control.enable.q),

    .axi_req_o,
    .axi_resp_i,

    .start_addr_i   ( {reg2hw.start_addr_high.q, reg2hw.start_addr_low.q}),
    .frame_size_i   ( reg2hw.frame_size.q ),
    .burst_len_i    ( reg2hw.burst_len.q  ),
    .red_o          ( red                 ),
    .green_o        ( green               ),
    .blue_o         ( blue                ),
    .fifo_valid        ( valid               ),
    .ready_i        ( ready               ),
    .fifo_ready_i        ( fifo_ready               ),
    .start_sync ,
    .mode_game_en (|reg2hw.fifo_depth.q)
  );

  // Cycle counter register
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(~rst_ni) begin
      clk_cnt_q <= '0;
    end else begin
      clk_cnt_q <= clk_cnt_d;
    end
  end


  /////////////////////
  // Some assertions //
  /////////////////////

  // Ensure a pixel is always smaller than or equal to a word
  assert property (@(posedge clk_i) AXIDataWidth >= (RedWidth + GreenWidth + BlueWidth)) else begin
    $error("AXIDataWidth has to be larger than or equal to the pixel width");
    $stop();
  end

  // Ensure the word width is a multiple of the pixel width
  assert property (@(posedge clk_i)
      (AXIDataWidth % (RedWidth + GreenWidth + BlueWidth)) == 0) else begin
    $error("AXIDataWidth has to be a multiple of the pixel width");
    $stop();
  end

endmodule
