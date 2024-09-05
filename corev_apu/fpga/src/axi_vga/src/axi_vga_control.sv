// Simple VGA IP capable of drawing frames from an external framebuffer.

// Description: Control memory acces
// Author: Abdou Lahat NDIAYE <abdou-lahat.ndiaye@thalesgroup.com>


module axi_vga_control #(
  parameter int unsigned AXIAddrWidth = 64,
  parameter int unsigned AXIDataWidth = 64,
  parameter int unsigned AXIStrbWidth = 8,
  parameter type axi_req_t            = logic,
  parameter type axi_resp_t           = logic,
  localparam int unsigned AXIStrbWidthClog2 = $clog2(AXIStrbWidth)
)(
  input logic                     clk_i,
  input logic                     rst_ni,
  input logic                     enable_i,

  output axi_req_t                axi_req_o,
  input  axi_resp_t               axi_resp_i,

  // VGA interface
  input  logic [63:0]             start_addr_i,
  input  logic [31:0]             frame_size_i,
  input  logic [7:0]              burst_len_i,

//Outgoing pixel data to stream_pixel
	output	logic				M_AXIS_TVALID,
	input	logic				M_AXIS_TREADY,
	output	logic	[AXIDataWidth-1:0]	M_AXIS_TDATA

);
    logic fifo_empty, sfifo_full, n_fifo_valid;
    logic  sfifo_ready;

  typedef enum logic       {R_IDLE, REQ} req_state_t;

  req_state_t req_state_q, req_state_d;

  axi_req_t axi_req;
  axi_resp_t axi_resp;

  logic [AXIAddrWidth-1:0] addr_page_mask, start_addr;
  logic [AXIAddrWidth-1:0] req_addr_q, req_addr_d;


  logic [AXIAddrWidth-1:0] frame_start_q, frame_start_d;
  logic [31:0] frame_size_q, frame_size_d, remaining_len;
  logic [7:0]  burst_len_q, burst_len_d, last_len_d, last_len_q;

  logic resp_last_q;

  logic first_req_q, first_req_d;

  assign axi_req_o = axi_req;
  assign axi_resp = axi_resp_i;

  assign axi_req.aw = '0;
  assign axi_req.aw_valid = '0;
  assign axi_req.w = '0;
  assign axi_req.w_valid = '0;
  assign axi_req.b_ready = '0;

  // Truncate or extend the fixed 64 bit we get from the regfile to the actual address width
  localparam int ZeroRepl = (AXIAddrWidth > 64) ? AXIAddrWidth - 64 : 0;
  assign start_addr = (AXIAddrWidth <= 64) ?
      start_addr_i[AXIAddrWidth-1:0] : {{ZeroRepl{1'b0}}, start_addr_i};

  // Create an AXIAddrWidth wide mask to ignore the lower 12 bit
  localparam int PageRemainingBits = AXIAddrWidth - 12;
  assign addr_page_mask = {{PageRemainingBits{1'b1}}, 12'h0};

  // How many bytes of a frame are left
  assign remaining_len  = frame_size_q-(req_addr_q-frame_start_q);


  // FSM to send requests
  always_comb begin
    frame_start_d     = frame_start_q;
    frame_size_d      = frame_size_q;
    burst_len_d       = burst_len_q;
    last_len_d        = last_len_q;
    first_req_d       = first_req_q;
    req_state_d       = req_state_q;
    req_addr_d        = req_addr_q;

    axi_req.ar        = '0;
    axi_req.ar.addr   = req_addr_q;
    axi_req.ar.burst  = 2'b01;    // Increasing burst
    axi_req.ar.cache  = 4'b0010;
    axi_req.ar.id     = '0;       // Explicitely state that we're using ID 0
    //axi_req.ar.prot   = 3'b010;
    axi_req.ar.size   = AXIStrbWidthClog2[2:0];
    axi_req.ar_valid  = 1'b0;

    unique case (req_state_q)

      REQ: begin
        if(enable_i) begin
                axi_req.ar.len = burst_len_q;
              	last_len_d     = burst_len_q;

          if(remaining_len > (burst_len_q+1)*AXIStrbWidth) begin
            if(req_addr_q[AXIAddrWidth-1:12] ==
                ((req_addr_q + (burst_len_q+1)*AXIStrbWidth) >> 12)) begin
              // Not the last request of frame
              axi_req.ar.len = burst_len_q;
              last_len_d     = burst_len_q;
            end else begin
              axi_req.ar.len =
                ((((req_addr_q + 4096) & addr_page_mask) - req_addr_q) >> AXIStrbWidthClog2)-1;
              last_len_d     =
                ((((req_addr_q + 4096) & addr_page_mask) - req_addr_q) >> AXIStrbWidthClog2)-1;
            end
          end else begin
            if(req_addr_q[AXIAddrWidth-1:12] == ((req_addr_q + remaining_len) >> 12)) begin
              // Last part of frame is within 4k boundary
              axi_req.ar.len = (remaining_len >> AXIStrbWidthClog2)-1;
              last_len_d     = (remaining_len >> AXIStrbWidthClog2)-1;
            end else begin
              axi_req.ar.len =
                ((((req_addr_q + 4096) & addr_page_mask) - req_addr_q) >> AXIStrbWidthClog2)-1;
              last_len_d     =
                ((((req_addr_q + 4096) & addr_page_mask) - req_addr_q) >> AXIStrbWidthClog2)-1;
            end
          end
          
	  if (fifo_empty) begin
	  	axi_req.ar_valid = 1'b1;
		if((axi_resp.ar_ready)) begin
		    req_state_d = R_IDLE;
		end
          end

        end else begin
          axi_req.ar_valid = 1'b0;

          first_req_d   = 1'b1;
          frame_start_d = start_addr;
          frame_size_d  = frame_size_i;
          burst_len_d   = burst_len_i;
          req_addr_d    = start_addr;
        end
      end

      R_IDLE: begin
        axi_req.ar_valid = 1'b0;

        if(enable_i) begin
          if((axi_resp.r_valid & axi_resp.r.last & !resp_last_q) | first_req_q) begin
            req_state_d = REQ;
            first_req_d = 1'b0;
            if((req_addr_q >= frame_start_q+frame_size_q-((last_len_q+1)*AXIStrbWidth))) begin
              // Was last REQ
              frame_start_d = start_addr;
              frame_size_d = frame_size_i;
              burst_len_d = burst_len_i;
              req_addr_d = start_addr;
            end else begin
              req_addr_d = req_addr_q + ((last_len_q+1)*AXIStrbWidth);
            end
          end
        end else begin
          req_state_d = REQ;
        end
      end

      default: begin
        req_state_d = REQ;
      end
    endcase
  end



    
    assign axi_req.r_ready  = ~sfifo_full;

    assign M_AXIS_TVALID  = ~fifo_empty;

    assign sfifo_ready = ~sfifo_full && axi_resp.r_valid;
    
 fifo_v3 #(
        .dtype(logic [AXIDataWidth-1:0]),
        .DEPTH(32'h200),
        .FALL_THROUGH(1'b1)
    ) i_s_fifo (
        .clk_i,
        .rst_ni,
        .flush_i   (1'b0),
        .testmode_i(1'b0),
        .full_o    (sfifo_full), //ready
        .empty_o   (fifo_empty), //valid
        .usage_o   (),
        .data_i    (axi_resp.r.data),
        .push_i    (sfifo_ready),
        .data_o    (M_AXIS_TDATA),
        .pop_i     (M_AXIS_TVALID && M_AXIS_TREADY)
    );
    
    
  // Flip-Flops
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if(!rst_ni) begin
      frame_start_q           <= '0;
      frame_size_q            <= '0;
      burst_len_q             <= '0;
      last_len_q              <= '0;
      first_req_q             <= 1'b1;
      req_state_q             <= REQ;
      req_addr_q              <= '0;

      
      resp_last_q             <= 1'b0;
      
    end else begin
      frame_start_q           <= frame_start_d;
      frame_size_q            <= frame_size_d;
      burst_len_q             <= burst_len_d;
      last_len_q              <= last_len_d;
      first_req_q             <= first_req_d;
      req_state_q             <= req_state_d;
      req_addr_q              <= req_addr_d;

    
      resp_last_q             <= axi_resp.r.last;
 
      

    end
  end
endmodule
