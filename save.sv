  logic [5:0] mem[16];
  logic [3:0] ptr_rd;
  logic [3:0] ptr_wr;

  always_ff @(posedge dram.ar_valid or negedge ndmreset_n) begin
    if (~ndmreset_n) begin
      ptr_wr <= 0;
    end else if(dram.ar_valid) begin
      mem[ptr_wr] <= dram.ar_id;
      ptr_wr <= ptr_wr + 1;
    end
  end

  always_ff @(negedge dram.r_valid or negedge ndmreset_n) begin
    if (~ndmreset_n) begin
      ptr_rd <= 0;
    end else if(~dram.r_valid) begin
      ptr_rd <= ptr_rd + 1;
    end
  end

  assign dram.r_id = mem[ptr_rd];