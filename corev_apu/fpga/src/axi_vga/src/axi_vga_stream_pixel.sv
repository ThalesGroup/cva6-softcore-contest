// Simple VGA IP capable of drawing frames from an external framebuffer.

// Description: Genrate RGB pixel from DATA streaming
// Author: Abdou Lahat NDIAYE <abdou-lahat.ndiaye@thalesgroup.com>


module axi_vga_stream_pixel #(
  parameter int unsigned RedWidth     = 5,
  parameter int unsigned GreenWidth   = 6,
  parameter int unsigned BlueWidth    = 5,
  parameter int unsigned AXIAddrWidth = 64,
  parameter int unsigned AXIDataWidth = 64,
  parameter int unsigned AXIStrbWidth = 8,
  localparam int unsigned AXIStrbWidthClog2 = $clog2(AXIStrbWidth)
)(
  input logic                     pxl_clk,
  input logic                     rst_ni,
  input logic                     enable_i,
  input logic                     fsm_en_i,


  // VGA interface
  output logic [RedWidth-1:0]     red_o,
  output logic [GreenWidth-1:0]   green_o,
  output logic [BlueWidth-1:0]    blue_o,

  input  logic timing_ready_i,
  
  		// Incoming video data from aFIFO
	input	wire				S_AXIS_TVALID,
	output	wire				S_AXIS_TREADY,
	input	wire [AXIDataWidth-1:0]	S_AXIS_TDATA
);

  localparam int unsigned PixelWidth = RedWidth + GreenWidth + BlueWidth;

  logic  [15:0] offset_fifo_d, offset_fifo_q;

  
  assign blue_o   = (S_AXIS_TVALID && timing_ready_i)? S_AXIS_TDATA[offset_fifo_q[AXIStrbWidthClog2+3-1:0] +:BlueWidth] : 'b0;
  assign green_o  = (S_AXIS_TVALID && timing_ready_i)? S_AXIS_TDATA[offset_fifo_q[AXIStrbWidthClog2+3-1:0] + BlueWidth +:GreenWidth] : 'b0;
  assign red_o    = (S_AXIS_TVALID && timing_ready_i)? S_AXIS_TDATA[offset_fifo_q[AXIStrbWidthClog2+3-1:0] + BlueWidth + GreenWidth +:RedWidth] : 'b0;

  assign S_AXIS_TREADY =  (offset_fifo_d == AXIDataWidth) && timing_ready_i && fsm_en_i;
    
      // Offset_fifo counter
  always_comb begin
    offset_fifo_d = offset_fifo_q;

    if(enable_i) begin
      if(timing_ready_i && fsm_en_i) begin
        offset_fifo_d = offset_fifo_q + PixelWidth; // Default when we sent out a pixel

        // We send out a pixel and at the same time fetch the next beat
        if (offset_fifo_q > AXIDataWidth) begin
          offset_fifo_d = offset_fifo_q - AXIDataWidth + PixelWidth;
        end
      end 
      // We fetched the next beat
    /*else if
          (offset_fifo_q >= AXIDataWidth) begin
        offset_fifo_d = offset_fifo_q - AXIDataWidth;
      end*/
    end else begin
      offset_fifo_d = 16'h0;
    end
  end
  
  

  
   // Flip-Flops
  always_ff @(posedge pxl_clk, negedge rst_ni) begin
    if(!rst_ni) begin
      offset_fifo_q                <= AXIDataWidth[15:0] +PixelWidth[15:0];

    end else begin
      offset_fifo_q 		<= offset_fifo_d;
      

    end
  end
endmodule
