// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

// takes X byte burst and splits it into pixels to hand over to the vga timing fsm
// TODO: do pixel length modularly

module axi_vga_fetcher #(
  parameter int unsigned RedWidth     = 5,
  parameter int unsigned GreenWidth   = 6,
  parameter int unsigned BlueWidth    = 5,
  parameter int unsigned AXIAddrWidth = 64,
  parameter int unsigned AXIDataWidth = 64,
  parameter int unsigned AXIStrbWidth = 8,
  parameter type axi_req_t            = logic,
  parameter type axi_resp_t           = logic,
  localparam int unsigned AXIStrbWidthClog2 = $clog2(AXIStrbWidth)
)(
  input logic                     clk_i,pxl_clk,
  input logic                     rst_ni,
  input logic                     enable_i,

  output axi_req_t                axi_req_o,
  input  axi_resp_t               axi_resp_i,

  // VGA interface
  input  logic [63:0]             start_addr_i,
  input  logic [31:0]             frame_size_i,
  input  logic [7:0]              burst_len_i,
  output logic [RedWidth-1:0]     red_o,
  output logic [GreenWidth-1:0]   green_o,
  output logic [BlueWidth-1:0]    blue_o,
  output logic                    fifo_valid,
  input  logic                    ready_i, 
  input  logic fifo_ready_i,
    input logic             start_sync ,
      input logic mode_game_en

);

  localparam int unsigned PixelWidth = RedWidth + GreenWidth + BlueWidth;

    logic  [15:0] offset_fifo_d, offset_fifo_q;
  typedef enum logic       {R_IDLE, REQ} req_state_t;

  req_state_t req_state_q, req_state_d;

  axi_req_t axi_req;
  axi_resp_t axi_resp;
  
    logic resp_last_q;
  
logic [2:0] count_q, count_d  ;
  typedef enum logic   [1:0]    {IDLE, EN_REQ, NO_REQ, NO_REQ_IDLE} en_req_state_t;

  en_req_state_t en_req_state_q, en_req_state_d;
  logic enable_req; 
  logic start_req, acq_ar ;
   


  logic [AXIAddrWidth-1:0] addr_page_mask, start_addr;
  logic [AXIAddrWidth-1:0] req_addr_q, req_addr_d;
  logic [AXIDataWidth-1:0] new_beat_data_d_o,sfifo_data_o ;
  
  logic fifo_empty, fifo_full, fifo_ready,  n_fifo_valid, n_ready_i;
  logic sfifo_empty, sfifo_full, sfifo_ready,  sfifo_valid;

  logic [AXIAddrWidth-1:0] frame_start_q, frame_start_d;
  logic [31:0] frame_size_q, frame_size_d, remaining_len;
  logic [7:0]  burst_len_q, burst_len_d, last_len_d, last_len_q;

logic [31:0] count_req_d, count_req_q;

  logic first_req_q, first_req_d;

logic afifo_pop;
logic resize_en, n_resize_en;



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

  assign blue_o   = new_beat_data_d_o[offset_fifo_q[AXIStrbWidthClog2+3-1:0] +:BlueWidth];
  assign green_o  = new_beat_data_d_o[offset_fifo_q[AXIStrbWidthClog2+3-1:0] + BlueWidth +:GreenWidth];
  assign red_o    = new_beat_data_d_o[offset_fifo_q[AXIStrbWidthClog2+3-1:0]
      + BlueWidth + GreenWidth +:RedWidth];

 always_comb begin
    enable_req = 1'b0;
    en_req_state_d       = en_req_state_q;
    count_d = count_q;
     unique case (en_req_state_q)

      EN_REQ: begin
        if(enable_i) begin
        
        	if (axi_resp.r_valid & axi_resp.r.last & !resp_last_q | first_req_q) en_req_state_d = NO_REQ_IDLE;

        	else begin
        	
        	 	enable_req = 1'b1;
		end
        end
      end
      
      IDLE: begin
      	if(enable_i) begin

		if(ready_i) begin
						enable_req = 1'b1;
			if (count_q == 3'h1) begin

				en_req_state_d = EN_REQ;
				count_d = 3'h0;
			end
			else begin 
				en_req_state_d = NO_REQ;
				count_d = count_q + 3'h1;
			end
		end
        end
      end
      
      NO_REQ: begin
        if(enable_i) begin
        	if (axi_resp.r_valid & axi_resp.r.last & !resp_last_q | first_req_q) en_req_state_d = NO_REQ_IDLE;

        	else begin
        	
        	 	enable_req = 1'b1;
		end

        end
        end
      
      
      NO_REQ_IDLE:begin
      	if(enable_i) begin
	      	if (first_req_d) begin
				enable_req = 1'b1;
				en_req_state_d = EN_REQ;
				count_d = 3'h0;
		end
		else begin
			if(!ready_i) en_req_state_d = IDLE;
		end
	end
      end
      
      
     default: begin
        en_req_state_d = NO_REQ_IDLE;
      end   
        
     endcase
    end
      

assign start_req = sfifo_empty & (first_req_q | enable_req);
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
    axi_req.ar.id     = 4'h2;       // Explicitely state that we're using ID 0
    axi_req.ar.prot   = 3'b000;
    axi_req.ar.size   = AXIStrbWidthClog2[2:0];
    axi_req.ar_valid  = 1'b0;
acq_ar = 1'b0; 
count_req_d = count_req_q;
 //   axi_req.ar.user     = 2'h2;       // Explicitely state that we're using ID 0
    unique case (req_state_q)

      REQ: begin
       if(enable_i) begin
       if(  start_sync ) begin
          frame_start_d = start_addr;
          frame_size_d  = frame_size_i;
          burst_len_d   = burst_len_i;
          req_addr_d    = start_addr;
       end
        if (~start_req)
          axi_req.ar_valid = 1'b0;
        else begin
          axi_req.ar_valid = 1'b1;
          if(remaining_len > (burst_len_q+1)*AXIStrbWidth) begin
            if(req_addr_q[AXIAddrWidth-1:12] ==
                ((req_addr_q + (burst_len_q+1)*AXIStrbWidth) >> 12)) begin
              // Not the last request of frame
              axi_req.ar.len = burst_len_q;
              last_len_d     = burst_len_q;
            end else begin
         /*     axi_req.ar.len =
                ((((req_addr_q + 4096) & addr_page_mask) - req_addr_q) >> AXIStrbWidthClog2)-1;
              last_len_d     =
                ((((req_addr_q + 4096) & addr_page_mask) - req_addr_q) >> AXIStrbWidthClog2)-1;*/
                   axi_req.ar.len = burst_len_q;
              last_len_d     = burst_len_q;
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

          if(axi_resp.ar_ready) begin 
            req_state_d = R_IDLE;
            acq_ar = 1'b1;
          end
	end //sfifo_empty
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
              if (en_req_state_q == NO_REQ)req_addr_d = start_addr;
            end else begin
            if ((en_req_state_q == NO_REQ) & !first_req_q) begin req_addr_d = req_addr_q + ((last_len_q+1)*AXIStrbWidth); count_req_d = count_req_q + 32'h1; end
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
assign fifo_valid  = ~fifo_empty;
    assign fifo_ready = ~fifo_full;
    
    
      // Offset_fifo counter
  always_comb begin
    offset_fifo_d = offset_fifo_q;
      resize_en = n_resize_en;
    if(enable_i) begin
      if(n_fifo_valid & fifo_ready_i) begin
      resize_en = ~n_resize_en;
      if (resize_en) begin
        offset_fifo_d = offset_fifo_q + PixelWidth; // Default when we sent out a pixel

        // We send out a pixel and at the same time fetch the next beat
        if (offset_fifo_q > AXIDataWidth) begin
          offset_fifo_d = offset_fifo_q - AXIDataWidth + PixelWidth;
        end
end //resize_en
      // We fetched the next beat
      end /*else if
          (offset_fifo_q >= AXIDataWidth) begin
        offset_fifo_d = offset_fifo_q - AXIDataWidth;
      end*/
    end else begin
      offset_fifo_d = 16'h0;
    end
  end
  
 assign sfifo_valid = ~sfifo_empty && !fifo_full & ready_i;
 assign sfifo_ready = ~sfifo_full && axi_resp.r_valid;
 // assign sfifo_data_i = N
   fifo_v3 #(
        .dtype(logic [AXIDataWidth-1:0]),
        .DEPTH(32'h50),
        .FALL_THROUGH(1'b1)
    ) i_s_fifo (
        .clk_i,
        .rst_ni,
        .flush_i   (1'b0),
        .testmode_i(1'b0),
        .full_o    (sfifo_full), //ready
        .empty_o   (sfifo_empty), //valid
        .usage_o   (),
        .data_i    (axi_resp.r.data),
        .push_i    (sfifo_ready ),
        .data_o    (sfifo_data_o),
        .pop_i     (sfifo_valid )
    );
    
   assign afifo_pop =  fifo_valid && ((offset_fifo_d == AXIDataWidth)||(offset_fifo_d == PixelWidth)) && fifo_ready_i && resize_en;

    afifo #(
		// {{{
		.LGFIFO(6), .WIDTH(AXIDataWidth)
		// }}}
	) i_a_fifo(
		// {{{
		// Write (incoming) interface--bus clock
		.i_wclk(clk_i), .i_wr_reset_n(rst_ni),
		.i_wr(sfifo_valid ),
			.i_wr_data(sfifo_data_o),
			.o_wr_full(fifo_full),
		//
		// Read (outgoing) interface--pixel clock
		.i_rclk(pxl_clk), .i_rd_reset_n(rst_ni),
		.i_rd (afifo_pop),
			.o_rd_data(new_beat_data_d_o),
			.o_rd_empty(fifo_empty)
		// }}}
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
      
      en_req_state_q             <= NO_REQ_IDLE;
      count_req_q =32'h0;
   count_q = 3'h1;
    end else begin
      frame_start_q           <= frame_start_d;
      frame_size_q            <= frame_size_d;
      burst_len_q             <= burst_len_d;
      last_len_q              <= last_len_d;
      first_req_q             <= first_req_d;
      req_state_q             <= req_state_d;
      req_addr_q              <= req_addr_d;

      resp_last_q             <= axi_resp.r.last;

	en_req_state_q             <= en_req_state_d;
	count_q = count_d;
	count_req_q =count_req_d;
    end
  end
  
  
   // Flip-Flops
  always_ff @(posedge pxl_clk, negedge rst_ni) begin
    if(!rst_ni) begin
      offset_fifo_q                <= AXIDataWidth[15:0] +PixelWidth[15:0];

      n_ready_i    <= 1'b0;

      n_fifo_valid <= 1'b0;
      n_resize_en <=1'b1;
    end else begin
      offset_fifo_q 		<= offset_fifo_d;
      
      n_fifo_valid <= fifo_valid;
	n_ready_i <= enable_i;
n_resize_en <= resize_en;
    end
  end
endmodule