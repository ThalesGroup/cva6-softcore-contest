// Simple VGA IP capable of drawing frames from an external framebuffer.

// Description: Re-synchronize data_in & data_out
// Author: Abdou Lahat NDIAYE <abdou-lahat.ndiaye@thalesgroup.com>


module axi_vga_afifo #(
  parameter int unsigned AXIDataWidth = 64,
  parameter int unsigned Depth       = 6
)(
	input logic                     clk_i,
	input logic                     pxl_clk,
	input logic                     rst_ni,
	input logic                     enable_i,

// Incoming pixel data from Fetcher
	input	wire				S_AXIS_TVALID,
	output	wire				S_AXIS_TREADY,
	input	wire [AXIDataWidth-1:0]	S_AXIS_TDATA,
	
//Outgoing pixel data to stream_pixel
	output	logic				M_AXIS_TVALID,
	input	logic				M_AXIS_TREADY,
	output	logic	[AXIDataWidth-1:0]	M_AXIS_TDATA
);


 if (Depth == '0) begin : gen_no_afifo
    // degenerate case, connect input to output
    assign M_AXIS_TDATA  = S_AXIS_TDATA;
    assign M_AXIS_TVALID = S_AXIS_TVALID;
    assign S_AXIS_TREADY = M_AXIS_TREADY;
  
  end else begin : gen_axi_afifo
  
    logic fifo_empty, fifo_full;

    assign M_AXIS_TVALID  = ~fifo_empty;

    assign S_AXIS_TREADY = ~fifo_full;

   afifo #(
		// {{{
		.LGFIFO(6),
		.WIDTH(AXIDataWidth)
		// }}}
	) i_a_fifo(
		// {{{
		// Write (incoming) interface--bus clock
		.i_wclk(clk_i), .i_wr_reset_n(rst_ni),
		.i_wr(S_AXIS_TVALID && S_AXIS_TREADY ),
			.i_wr_data(S_AXIS_TDATA),
			.o_wr_full(fifo_full),
		//
		// Read (outgoing) interface--pixel clock
		.i_rclk(pxl_clk), .i_rd_reset_n(rst_ni),
		.i_rd (M_AXIS_TVALID && M_AXIS_TREADY),
			.o_rd_data(M_AXIS_TDATA),
			.o_rd_empty(fifo_empty)
		// }}}
	);
	/*
	    
 fifo_v3 #(
        .dtype(logic [AXIDataWidth-1:0]),
        .DEPTH(32'h24),
        .FALL_THROUGH(1'b1)
    ) i_s_fifo_axi (
        .clk_i,
        .rst_ni,
        .flush_i   (1'b0),
        .testmode_i(1'b0),
        .full_o    (fifo_full), //ready
        .empty_o   (fifo_empty), //valid
        .usage_o   (),
        .data_i    (S_AXIS_TDATA),
        .push_i    (S_AXIS_TVALID && S_AXIS_TREADY),
        .data_o    (M_AXIS_TDATA),
        .pop_i     (M_AXIS_TVALID && M_AXIS_TREADY)
    );
    */
	
  end
  
endmodule

