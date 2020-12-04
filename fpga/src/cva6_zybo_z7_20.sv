

module cva6_zybo_z7_20 (

//  input  logic          USER_SI570_P,
//  input  logic          USER_SI570_N,

input  logic          clk_sys,

  input  logic         cpu_reset   ,
//  output logic [ 7:0]  led         ,
//  input  logic [ 7:0]  sw          ,



  // common part
   input logic      trst_n      ,
  input  logic        tck         ,
  input  logic        tms         ,
  input  logic        tdi         ,
  output wire         tdo         ,
  input  logic        rx          ,
  output logic        tx
);
// 24 MByte in 8 byte words
localparam NumWords = (24 * 1024 * 1024) / 8;
localparam NBSlave = 2; // debug, ariane
localparam AxiAddrWidth = 64;
localparam AxiDataWidth = 64;
localparam AxiIdWidthMaster = 4;
localparam AxiIdWidthSlaves = AxiIdWidthMaster + $clog2(NBSlave); // 5
localparam AxiUserWidth = 1;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthMaster ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) slave[NBSlave-1:0]();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) master[ariane_soc::NB_PERIPHERALS-1:0]();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( 32     ),
    .AXI_DATA_WIDTH ( 32     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) master_to_dm[0:0]();

// disable test-enable
logic test_en;
logic ndmreset;
logic ndmreset_n;
logic debug_req_irq;
logic time_irq;
logic ipi;

logic clk;
logic eth_clk;
logic spi_clk_i;
logic phy_tx_clk;
logic sd_clk_sys;


logic ps_clock_out;

logic rst_n, rst;
logic rtc;


//assign trst_n = 1'b1;
//assign trst_n = ndmreset_n;

logic pll_locked;

// ROM
logic                    rom_req;
logic [AxiAddrWidth-1:0] rom_addr;
logic [AxiDataWidth-1:0] rom_rdata;

// Debug
logic          debug_req_valid;
logic          debug_req_ready;
dm::dmi_req_t  debug_req;
logic          debug_resp_valid;
logic          debug_resp_ready;
dm::dmi_resp_t debug_resp;

logic dmactive;

// IRQ
logic [1:0] irq;
assign test_en    = 1'b0;

logic [NBSlave-1:0] pc_asserted;

logic dmi_trst_n;

rstgen i_rstgen_main (
    .clk_i        ( clk                      ),
    .rst_ni       ( pll_locked & (~ndmreset) ),
    .test_mode_i  ( test_en                  ),
    .rst_no       ( ndmreset_n               ),
    .init_no      (                          ) // keep open
);



//assign rst_n = ndmreset_n;
//assign rst = ~ndmreset_n;

assign rst_n = ~cpu_reset;
assign rst = cpu_reset;

// ---------------
// AXI Xbar
// ---------------
axi_node_wrap_with_slices #(
    // three ports from Ariane (instruction, data and bypass)
    .NB_SLAVE           ( NBSlave                    ),
    .NB_MASTER          ( ariane_soc::NB_PERIPHERALS ),
    .NB_REGION          ( ariane_soc::NrRegion       ),
    .AXI_ADDR_WIDTH     ( AxiAddrWidth               ),
    .AXI_DATA_WIDTH     ( AxiDataWidth               ),
    .AXI_USER_WIDTH     ( AxiUserWidth               ),
    .AXI_ID_WIDTH       ( AxiIdWidthMaster           ),
    .MASTER_SLICE_DEPTH ( 2                          ),
    .SLAVE_SLICE_DEPTH  ( 2                          )
) i_axi_xbar (
    .clk          ( clk        ),
    .rst_n        ( ndmreset_n ),
    .test_en_i    ( test_en    ),
    .slave        ( slave      ),
    .master       ( master     ),
    .start_addr_i ({
        ariane_soc::DebugBase,
        ariane_soc::ROMBase,
        ariane_soc::CLINTBase,
        ariane_soc::PLICBase,
        ariane_soc::UARTBase,
        ariane_soc::TimerBase,
        ariane_soc::SPIBase,
        ariane_soc::EthernetBase,
        ariane_soc::GPIOBase,
        ariane_soc::DRAMBase
    }),
    .end_addr_i   ({
        ariane_soc::DebugBase    + ariane_soc::DebugLength - 1,
        ariane_soc::ROMBase      + ariane_soc::ROMLength - 1,
        ariane_soc::CLINTBase    + ariane_soc::CLINTLength - 1,
        ariane_soc::PLICBase     + ariane_soc::PLICLength - 1,
        ariane_soc::UARTBase     + ariane_soc::UARTLength - 1,
        ariane_soc::TimerBase    + ariane_soc::TimerLength - 1,
        ariane_soc::SPIBase      + ariane_soc::SPILength - 1,
        ariane_soc::EthernetBase + ariane_soc::EthernetLength -1,
        ariane_soc::GPIOBase     + ariane_soc::GPIOLength - 1,
        ariane_soc::DRAMBase     + ariane_soc::DRAMLength - 1
    }),
    .valid_rule_i (ariane_soc::ValidRule)
);

`ifdef LAUTERBACH_DEBUG_PROBE
  assign dmi_trst_n = trst_n;
`else
  assign dmi_trst_n = 1'b1;
`endif

// ---------------
// Debug Module
// ---------------
dmi_jtag  #(
        .IdcodeValue          ( 32'h249511C3    )
    )i_dmi_jtag (
    .clk_i                ( clk                  ),
    .rst_ni               ( rst_n                ),
    .dmi_rst_no           (                      ), // keep open
    .testmode_i           ( test_en              ),
    .dmi_req_valid_o      ( debug_req_valid      ),
    .dmi_req_ready_i      ( debug_req_ready      ),
    .dmi_req_o            ( debug_req            ),
    .dmi_resp_valid_i     ( debug_resp_valid     ),
    .dmi_resp_ready_o     ( debug_resp_ready     ),
    .dmi_resp_i           ( debug_resp           ),
    .tck_i                ( tck    ),
    .tms_i                ( tms    ),
    //.trst_ni              ( trst_n ),
    .trst_ni              ( dmi_trst_n ),
    .td_i                 ( tdi    ),
    .td_o                 ( tdo    ),
    .tdo_oe_o             (        )
);

ariane_axi::req_t    dm_axi_m_req;
ariane_axi::resp_t   dm_axi_m_resp;

logic                dm_slave_req;
logic                dm_slave_we;
logic [32-1:0]       dm_slave_addr;
logic [32/8-1:0]     dm_slave_be;
logic [32-1:0]       dm_slave_wdata;
logic [32-1:0]       dm_slave_rdata;

logic                dm_master_req;
logic [32-1:0]       dm_master_add;
logic                dm_master_we;
logic [32-1:0]       dm_master_wdata;
logic [32/8-1:0]     dm_master_be;
logic                dm_master_gnt;
logic                dm_master_r_valid;
logic [32-1:0]       dm_master_r_rdata;

// debug module
dm_top #(
    .NrHarts          ( 1                 ),
    .BusWidth         ( 32      ),
    .SelectableHarts  ( 1'b1              )
) i_dm_top (
    .clk_i            ( clk               ),
    .rst_ni           ( rst_n             ), // PoR
    .testmode_i       ( test_en           ),
    .ndmreset_o       ( ndmreset          ),
    .dmactive_o       ( dmactive          ), // active debug session
    .debug_req_o      ( debug_req_irq     ),
    .unavailable_i    ( '0                ),
    .hartinfo_i       ( {ariane_pkg::DebugHartInfo} ),
    .slave_req_i      ( dm_slave_req      ),
    .slave_we_i       ( dm_slave_we       ),
    .slave_addr_i     ( dm_slave_addr     ),
    .slave_be_i       ( dm_slave_be       ),
    .slave_wdata_i    ( dm_slave_wdata    ),
    .slave_rdata_o    ( dm_slave_rdata    ),
    .master_req_o     ( dm_master_req     ),
    .master_add_o     ( dm_master_add     ),
    .master_we_o      ( dm_master_we      ),
    .master_wdata_o   ( dm_master_wdata   ),
    .master_be_o      ( dm_master_be      ),
    .master_gnt_i     ( dm_master_gnt     ),
    .master_r_valid_i ( dm_master_r_valid ),
    .master_r_rdata_i ( dm_master_r_rdata ),
    .dmi_rst_ni       ( rst_n             ),
    .dmi_req_valid_i  ( debug_req_valid   ),
    .dmi_req_ready_o  ( debug_req_ready   ),
    .dmi_req_i        ( debug_req         ),
    .dmi_resp_valid_o ( debug_resp_valid  ),
    .dmi_resp_ready_i ( debug_resp_ready  ),
    .dmi_resp_o       ( debug_resp        )
);
/********************************************************/
axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves    ),
    .AXI_ADDR_WIDTH ( 32        ),
    .AXI_DATA_WIDTH ( 32        ),
    .AXI_USER_WIDTH ( AxiUserWidth        )
) i_dm_axi2mem (
    .clk_i      ( clk                       ),
    .rst_ni     ( rst_n                     ),
//    .slave      ( master[ariane_soc::Debug] ),
    .slave      ( master_to_dm[0] ),
    .req_o      ( dm_slave_req              ),
    .we_o       ( dm_slave_we               ),
    .addr_o     ( dm_slave_addr             ),
    .be_o       ( dm_slave_be               ),
    .data_o     ( dm_slave_wdata            ),
    .data_i     ( dm_slave_rdata            )
);



assign master_to_dm[0].aw_user = '0;
assign master_to_dm[0].w_user = '0;
assign master_to_dm[0].ar_user = '0;

assign master_to_dm[0].aw_id = dm_axi_m_req.aw.id;
//assign master_to_dm[0].b_id = dm_axi_m_resp.b.id;
//assign dm_axi_m_resp.b.id = master_to_dm[0].b_id;
assign master_to_dm[0].ar_id = dm_axi_m_req.ar.id;
//assign master_to_dm[0].r_id = dm_axi_m_resp.r.id;
//assign dm_axi_m_resp.r.id = master_to_dm[0].r_id;

assign master[ariane_soc::Debug].r_user ='0;
assign master[ariane_soc::Debug].b_user ='0;

//assign master[ariane_soc::Debug].b_id = master_to_dm[0].b_id;
//assign master[ariane_soc::Debug].r_id = master_to_dm[0].r_id;



xlnx_axi_dwidth_converter_dm_slave  i_axi_dwidth_converter_dm_slave( 
    .s_axi_aclk(clk),// : in STD_LOGIC;
    .s_axi_aresetn(ndmreset_n),// : in STD_LOGIC;
    .s_axi_awid(master[ariane_soc::Debug].aw_id),// : in STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_awaddr(master[ariane_soc::Debug].aw_addr[31:0]),// : in STD_LOGIC_VECTOR ( 31 downto 0 );
    .s_axi_awlen(master[ariane_soc::Debug].aw_len),// : in STD_LOGIC_VECTOR ( 7 downto 0 );
    .s_axi_awsize(master[ariane_soc::Debug].aw_size),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_awburst(master[ariane_soc::Debug].aw_burst),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_awlock(master[ariane_soc::Debug].aw_lock),// : in STD_LOGIC_VECTOR ( 0 to 0 );
    .s_axi_awcache(master[ariane_soc::Debug].aw_cache),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_awprot(master[ariane_soc::Debug].aw_prot),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_awregion(master[ariane_soc::Debug].aw_region),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_awqos(master[ariane_soc::Debug].aw_qos),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_awvalid(master[ariane_soc::Debug].aw_valid),// : in STD_LOGIC;
    .s_axi_awready(master[ariane_soc::Debug].aw_ready),// : out STD_LOGIC;
    .s_axi_wdata(master[ariane_soc::Debug].w_data),// : in STD_LOGIC_VECTOR ( 63 downto 0 );
    .s_axi_wstrb(master[ariane_soc::Debug].w_strb),// : in STD_LOGIC_VECTOR ( 7 downto 0 );
    .s_axi_wlast(master[ariane_soc::Debug].w_last),// : in STD_LOGIC;
    .s_axi_wvalid(master[ariane_soc::Debug].w_valid),// : in STD_LOGIC;
    .s_axi_wready(master[ariane_soc::Debug].w_ready),// : out STD_LOGIC;
    .s_axi_bid(master[ariane_soc::Debug].b_id),// : out STD_LOGIC_VECTOR ( 4 downto 0 );
    //.s_axi_bid(),// : out STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_bresp(master[ariane_soc::Debug].b_resp),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_bvalid(master[ariane_soc::Debug].b_valid),// : out STD_LOGIC;
    .s_axi_bready(master[ariane_soc::Debug].b_ready),// : in STD_LOGIC;
    .s_axi_arid(master[ariane_soc::Debug].ar_id),// : in STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_araddr(master[ariane_soc::Debug].ar_addr[31:0]),// : in STD_LOGIC_VECTOR ( 31 downto 0 );
    .s_axi_arlen(master[ariane_soc::Debug].ar_len),// : in STD_LOGIC_VECTOR ( 7 downto 0 );
    .s_axi_arsize(master[ariane_soc::Debug].ar_size),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_arburst(master[ariane_soc::Debug].ar_burst),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_arlock(master[ariane_soc::Debug].ar_lock),// : in STD_LOGIC_VECTOR ( 0 to 0 );
    .s_axi_arcache(master[ariane_soc::Debug].ar_cache),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_arprot(master[ariane_soc::Debug].ar_prot),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_arregion(master[ariane_soc::Debug].ar_region),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_arqos(master[ariane_soc::Debug].ar_qos),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_arvalid(master[ariane_soc::Debug].ar_valid),// : in STD_LOGIC;
    .s_axi_arready(master[ariane_soc::Debug].ar_ready),// : out STD_LOGIC;
    .s_axi_rid(master[ariane_soc::Debug].r_id),// : out STD_LOGIC_VECTOR ( 4 downto 0 );
    //.s_axi_rid(),// : out STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_rdata(master[ariane_soc::Debug].r_data),// : out STD_LOGIC_VECTOR ( 63 downto 0 );
    .s_axi_rresp(master[ariane_soc::Debug].r_resp),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_rlast(master[ariane_soc::Debug].r_last),// : out STD_LOGIC;
    .s_axi_rvalid(master[ariane_soc::Debug].r_valid),// : out STD_LOGIC;
    .s_axi_rready(master[ariane_soc::Debug].r_ready),// : in STD_LOGIC;
    .m_axi_awaddr(master_to_dm[0].aw_addr),// : out STD_LOGIC_VECTOR ( 31 downto 0 );
    .m_axi_awlen(master_to_dm[0].aw_len),// : out STD_LOGIC_VECTOR ( 7 downto 0 );
    .m_axi_awsize(master_to_dm[0].aw_size),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_awburst(master_to_dm[0].aw_burst),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_awlock(master_to_dm[0].aw_lock),// : out STD_LOGIC_VECTOR ( 0 to 0 );
    .m_axi_awcache(master_to_dm[0].aw_cache),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_awprot(master_to_dm[0].aw_prot),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_awregion(master_to_dm[0].aw_region),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_awqos(master_to_dm[0].aw_qos),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_awvalid(master_to_dm[0].aw_valid),// : out STD_LOGIC;
    .m_axi_awready(master_to_dm[0].aw_ready),// : in STD_LOGIC;
    .m_axi_wdata(master_to_dm[0].w_data ),// : out STD_LOGIC_VECTOR ( 31 downto 0 );
    .m_axi_wstrb(master_to_dm[0].w_strb),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_wlast(master_to_dm[0].w_last),// : out STD_LOGIC;
    .m_axi_wvalid(master_to_dm[0].w_valid),// : out STD_LOGIC;
    .m_axi_wready(master_to_dm[0].w_ready),// : in STD_LOGIC;
    .m_axi_bresp(master_to_dm[0].b_resp),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_bvalid(master_to_dm[0].b_valid),// : in STD_LOGIC;
    .m_axi_bready(master_to_dm[0].b_ready),// : out STD_LOGIC;
    .m_axi_araddr(master_to_dm[0].ar_addr),// : out STD_LOGIC_VECTOR ( 31 downto 0 );
    .m_axi_arlen(master_to_dm[0].ar_len),// : out STD_LOGIC_VECTOR ( 7 downto 0 );
    .m_axi_arsize(master_to_dm[0].ar_size),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_arburst(master_to_dm[0].ar_burst),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_arlock(master_to_dm[0].ar_lock),// : out STD_LOGIC_VECTOR ( 0 to 0 );
    .m_axi_arcache(master_to_dm[0].ar_cache),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_arprot(master_to_dm[0].ar_prot),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_arregion(master_to_dm[0].ar_region),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_arqos(master_to_dm[0].ar_qos),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_arvalid(master_to_dm[0].ar_valid),// : out STD_LOGIC;
    .m_axi_arready(master_to_dm[0].ar_ready),// : in STD_LOGIC;
    .m_axi_rdata(master_to_dm[0].r_data),// : in STD_LOGIC_VECTOR ( 31 downto 0 );
    .m_axi_rresp(master_to_dm[0].r_resp),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_rlast(master_to_dm[0].r_last),// : in STD_LOGIC;
    .m_axi_rvalid(master_to_dm[0].r_valid),// : in STD_LOGIC;
    .m_axi_rready(master_to_dm[0].r_ready)// : out STD_LOGIC
  );



/*axi_master_connect i_dm_axi_master_connect (
  .axi_req_i(dm_axi_m_req),
  .axi_resp_o(dm_axi_m_resp),
  .master(slave[1])
);*/
/*****************************************************************/
logic [31 : 0] dm_master_m_awaddr;
logic [31 : 0] dm_master_m_araddr;

assign slave[1].aw_addr = {32'h0000_0000, dm_master_m_awaddr};
assign slave[1].ar_addr = {32'h0000_0000, dm_master_m_araddr};

logic [31 : 0] dm_master_s_rdata;

assign dm_axi_m_resp.r.data = {32'h0000_0000, dm_master_s_rdata}; 

assign slave[1].aw_user = '0;
assign slave[1].w_user = '0;
assign slave[1].ar_user = '0;
//assign slave[1].b_user = '0;

assign slave[1].aw_id = dm_axi_m_req.aw.id;
//assign slave[1].b_id = dm_axi_m_resp.b.id;
///assign dm_axi_m_resp.b.id = slave[1].b_id;
assign slave[1].ar_id = dm_axi_m_req.ar.id;
//assign slave[1].r_id = dm_axi_m_resp.r.id;
//assign dm_axi_m_resp.r.id = slave[1].r_id;
assign slave[1].aw_atop = dm_axi_m_req.aw.atop;



xlnx_axi_dwidth_converter_dm_master  i_axi_dwidth_converter_dm_master( 
    .s_axi_aclk(clk),// : in STD_LOGIC;
    .s_axi_aresetn(ndmreset_n),// : in STD_LOGIC;
    .s_axi_awid(dm_axi_m_req.aw.id),// : in STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_awaddr(dm_axi_m_req.aw.addr[31:0]),// : in STD_LOGIC_VECTOR ( 31 downto 0 );
    .s_axi_awlen(dm_axi_m_req.aw.len),// : in STD_LOGIC_VECTOR ( 7 downto 0 );
    .s_axi_awsize(dm_axi_m_req.aw.size),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_awburst(dm_axi_m_req.aw.burst),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_awlock(dm_axi_m_req.aw.lock),// : in STD_LOGIC_VECTOR ( 0 to 0 );
    .s_axi_awcache(dm_axi_m_req.aw.cache),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_awprot(dm_axi_m_req.aw.prot),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_awregion(dm_axi_m_req.aw.region),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_awqos(dm_axi_m_req.aw.qos),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_awvalid(dm_axi_m_req.aw_valid),// : in STD_LOGIC;
    .s_axi_awready(dm_axi_m_resp.aw_ready),// : out STD_LOGIC;
    .s_axi_wdata(dm_axi_m_req.w.data[31:0]),// : in STD_LOGIC_VECTOR ( 31 downto 0 );
    .s_axi_wstrb(dm_axi_m_req.w.strb[3:0]),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_wlast(dm_axi_m_req.w.last),// : in STD_LOGIC;
    .s_axi_wvalid(dm_axi_m_req.w_valid),// : in STD_LOGIC;
    .s_axi_wready(dm_axi_m_resp.w_ready),// : out STD_LOGIC;
    .s_axi_bid(dm_axi_m_resp.b.id),// : out STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_bresp(dm_axi_m_resp.b.resp),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_bvalid(dm_axi_m_resp.b_valid),// : out STD_LOGIC;
    .s_axi_bready(dm_axi_m_req.b_ready),// : in STD_LOGIC;
    .s_axi_arid(dm_axi_m_req.ar.id),// : in STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_araddr(dm_axi_m_req.ar.addr[31:0]),// : in STD_LOGIC_VECTOR ( 31 downto 0 );
    .s_axi_arlen(dm_axi_m_req.ar.len),// : in STD_LOGIC_VECTOR ( 7 downto 0 );
    .s_axi_arsize(dm_axi_m_req.ar.size),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_arburst(dm_axi_m_req.ar.burst),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_arlock(dm_axi_m_req.ar.lock),// : in STD_LOGIC_VECTOR ( 0 to 0 );
    .s_axi_arcache(dm_axi_m_req.ar.cache),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_arprot(dm_axi_m_req.ar.prot),// : in STD_LOGIC_VECTOR ( 2 downto 0 );
    .s_axi_arregion(dm_axi_m_req.ar.region),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_arqos(dm_axi_m_req.ar.qos),// : in STD_LOGIC_VECTOR ( 3 downto 0 );
    .s_axi_arvalid(dm_axi_m_req.ar_valid),// : in STD_LOGIC;
    .s_axi_arready(dm_axi_m_resp.ar_ready),// : out STD_LOGIC;
    .s_axi_rid(dm_axi_m_resp.r.id),// : out STD_LOGIC_VECTOR ( 4 downto 0 );
    .s_axi_rdata(dm_master_s_rdata),// : out STD_LOGIC_VECTOR ( 31 downto 0 );
    .s_axi_rresp(dm_axi_m_resp.r.resp),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .s_axi_rlast(dm_axi_m_resp.r.last),// : out STD_LOGIC;
    .s_axi_rvalid(dm_axi_m_resp.r_valid),// : out STD_LOGIC;
    .s_axi_rready(dm_axi_m_req.r_ready),// : in STD_LOGIC;
    .m_axi_awaddr(dm_master_m_awaddr),// : out STD_LOGIC_VECTOR ( 31 downto 0 );
    .m_axi_awlen(slave[1].aw_len),// : out STD_LOGIC_VECTOR ( 7 downto 0 );
    .m_axi_awsize(slave[1].aw_size),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_awburst(slave[1].aw_burst),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_awlock(slave[1].aw_lock),// : out STD_LOGIC_VECTOR ( 0 to 0 );
    .m_axi_awcache(slave[1].aw_cache),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_awprot(slave[1].aw_prot),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_awregion(slave[1].aw_region),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_awqos(slave[1].aw_qos),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_awvalid(slave[1].aw_valid),// : out STD_LOGIC;
    .m_axi_awready(slave[1].aw_ready),// : in STD_LOGIC;
    .m_axi_wdata(slave[1].w_data ),// : out STD_LOGIC_VECTOR ( 63 downto 0 );
    .m_axi_wstrb(slave[1].w_strb),// : out STD_LOGIC_VECTOR ( 7 downto 0 );
    .m_axi_wlast(slave[1].w_last),// : out STD_LOGIC;
    .m_axi_wvalid(slave[1].w_valid),// : out STD_LOGIC;
    .m_axi_wready(slave[1].w_ready),// : in STD_LOGIC;
    .m_axi_bresp(slave[1].b_resp),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_bvalid(slave[1].b_valid),// : in STD_LOGIC;
    .m_axi_bready(slave[1].b_ready),// : out STD_LOGIC;
    .m_axi_araddr(dm_master_m_araddr),// : out STD_LOGIC_VECTOR ( 31 downto 0 );
    .m_axi_arlen(slave[1].ar_len),// : out STD_LOGIC_VECTOR ( 7 downto 0 );
    .m_axi_arsize(slave[1].ar_size),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_arburst(slave[1].ar_burst),// : out STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_arlock(slave[1].ar_lock),// : out STD_LOGIC_VECTOR ( 0 to 0 );
    .m_axi_arcache(slave[1].ar_cache),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_arprot(slave[1].ar_prot),// : out STD_LOGIC_VECTOR ( 2 downto 0 );
    .m_axi_arregion(slave[1].ar_region),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_arqos(slave[1].ar_qos),// : out STD_LOGIC_VECTOR ( 3 downto 0 );
    .m_axi_arvalid(slave[1].ar_valid),// : out STD_LOGIC;
    .m_axi_arready(slave[1].ar_ready),// : in STD_LOGIC;
    .m_axi_rdata(slave[1].r_data),// : in STD_LOGIC_VECTOR ( 63 downto 0 );
    .m_axi_rresp(slave[1].r_resp),// : in STD_LOGIC_VECTOR ( 1 downto 0 );
    .m_axi_rlast(slave[1].r_last),// : in STD_LOGIC;
    .m_axi_rvalid(slave[1].r_valid),// : in STD_LOGIC;
    .m_axi_rready(slave[1].r_ready)// : out STD_LOGIC
  );


/*axi_adapter #(
    .DATA_WIDTH            ( 32              )
) i_dm_axi_master (
    .clk_i                 ( clk                       ),
    .rst_ni                ( rst_n                     ),
    .req_i                 ( dm_master_req             ),
    .type_i                ( ariane_axi::SINGLE_REQ    ),
    .gnt_o                 ( dm_master_gnt             ),
    .gnt_id_o              (                           ),
    .addr_i                ( {32'h00000000, dm_master_add}             ),
    .we_i                  ( dm_master_we              ),
    .wdata_i               ( dm_master_wdata           ),
    .be_i                  ( dm_master_be              ),
    .size_i                ( 2'b11                     ), // always do 64bit here and use byte enables to gate
    .id_i                  ( '0                        ),
    .valid_o               ( dm_master_r_valid         ),
    .rdata_o               ( dm_master_r_rdata         ),
    .id_o                  (                           ),
    .critical_word_o       (                           ),
    .critical_word_valid_o (                           ),
    .axi_req_o             ( dm_axi_m_req              ),
    .axi_resp_i            ( dm_axi_m_resp             )
);*/

axi_adapter_32 #(
    .DATA_WIDTH            ( 32              )
) i_dm_axi_master (
    .clk_i                 ( clk                       ),
    .rst_ni                ( rst_n                     ),
    .req_i                 ( dm_master_req             ),
    .type_i                ( ariane_axi::SINGLE_REQ    ),
    .gnt_o                 ( dm_master_gnt             ),
    .gnt_id_o              (                           ),
    .addr_i                (  dm_master_add             ),
    .we_i                  ( dm_master_we              ),
    .wdata_i               ( dm_master_wdata           ),
    .be_i                  ( dm_master_be              ),
    .size_i                ( 2'b10                     ), // always do 32bit here and use byte enables to gate
    .id_i                  ( '0                        ),
    .valid_o               ( dm_master_r_valid         ),
    .rdata_o               ( dm_master_r_rdata         ),
    .id_o                  (                           ),
    .critical_word_o       (                           ),
    .critical_word_valid_o (                           ),
    .axi_req_o             ( dm_axi_m_req              ),
    .axi_resp_i            ( dm_axi_m_resp             )
);

// ---------------
// Core
// ---------------
ariane_axi::req_t    axi_ariane_req;
ariane_axi::resp_t   axi_ariane_resp;

ariane #(
    .ArianeCfg ( ariane_soc::ArianeSocCfg )
) i_ariane (
    .clk_i        ( clk                 ),
    .rst_ni       ( ndmreset_n          ),
    .boot_addr_i  ( ariane_soc::ROMBase[riscv::XLEN-1:0] ), // start fetching from ROM
    .hart_id_i    ( '0                  ),
    .irq_i        ( irq                 ),
    .ipi_i        ( ipi                 ),
    .time_irq_i   ( timer_irq           ),
    .debug_req_i  ( debug_req_irq       ),
    .axi_req_o    ( axi_ariane_req      ),
    .axi_resp_i   ( axi_ariane_resp     )
);

axi_master_connect i_axi_master_connect_ariane (.axi_req_i(axi_ariane_req), .axi_resp_o(axi_ariane_resp), .master(slave[0]));

// ---------------
// CLINT
// ---------------
// divide clock by two
always_ff @(posedge clk or negedge ndmreset_n) begin
  if (~ndmreset_n) begin
    rtc <= 0;
  end else begin
    rtc <= rtc ^ 1'b1;
  end
end

ariane_axi::req_t    axi_clint_req;
ariane_axi::resp_t   axi_clint_resp;

clint #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .NR_CORES       ( 1                )
) i_clint (
    .clk_i       ( clk            ),
    .rst_ni      ( ndmreset_n     ),
    .testmode_i  ( test_en        ),
    .axi_req_i   ( axi_clint_req  ),
    .axi_resp_o  ( axi_clint_resp ),
    .rtc_i       ( rtc            ),
    .timer_irq_o ( timer_irq      ),
    .ipi_o       ( ipi            )
);

axi_slave_connect i_axi_slave_connect_clint (.axi_req_o(axi_clint_req), .axi_resp_i(axi_clint_resp), .slave(master[ariane_soc::CLINT]));

// ---------------
// ROM
// ---------------
axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) i_axi2rom (
    .clk_i  ( clk                     ),
    .rst_ni ( ndmreset_n              ),
    .slave  ( master[ariane_soc::ROM] ),
    .req_o  ( rom_req                 ),
    .we_o   (                         ),
    .addr_o ( rom_addr                ),
    .be_o   (                         ),
    .data_o (                         ),
    .data_i ( rom_rdata               )
);

bootrom i_bootrom (
    .clk_i   ( clk       ),
    .req_i   ( rom_req   ),
    .addr_i  ( rom_addr  ),
    .rdata_o ( rom_rdata )
);



ariane_peripherals #(
    .AxiAddrWidth ( AxiAddrWidth     ),
    .AxiDataWidth ( AxiDataWidth     ),
    .AxiIdWidth   ( AxiIdWidthSlaves ),
    .AxiUserWidth ( AxiUserWidth     ),
    .InclUART     ( 1'b1             ),
    .InclGPIO     ( 1'b0             ),
    .InclSPI      ( 1'b0         ),
    .InclEthernet ( 1'b0         )

) i_ariane_peripherals (
    .clk_i        ( clk                          ),
    .clk_200MHz_i ( 1'b0               ),
    .rst_ni       ( ndmreset_n                   ),
    .plic         ( master[ariane_soc::PLIC]     ),
    .uart         ( master[ariane_soc::UART]     ),
    .spi          ( master[ariane_soc::SPI]      ),
    .gpio         ( master[ariane_soc::GPIO]     ),
    .eth_clk_i    ( eth_clk                      ),
    .ethernet     ( master[ariane_soc::Ethernet] ),
    .timer        ( master[ariane_soc::Timer]    ),
    .irq_o        ( irq                          ),
    .rx_i         ( rx                           ),
    .tx_o         ( tx                           ),
    .eth_txck (),
    .eth_rxck (1'b0),
    .eth_rxctl (1'b0),
    .eth_rxd (4'b0000),
    .eth_rst_n (),
    .eth_txctl (),
    .eth_txd (),
    .eth_mdio (),
    .eth_mdc (),
    .phy_tx_clk_i   ( phy_tx_clk                  ),
    .sd_clk_i       ( sd_clk_sys                  ),
    .spi_clk_o      ( spi_clk_o                   ),
    .spi_mosi       ( spi_mosi                    ),
    .spi_miso       ( spi_miso                    ),
    .spi_ss         ( spi_ss                      ),

      .leds_o         (                        ),
      .dip_switches_i (                        )

);


// ---------------------
// Board peripherals
// ---------------------
// ---------------
// DDR
// ---------------
logic [AxiIdWidthSlaves-1:0] s_axi_awid;
logic [AxiAddrWidth-1:0]     s_axi_awaddr;
logic [7:0]                  s_axi_awlen;
logic [2:0]                  s_axi_awsize;
logic [1:0]                  s_axi_awburst;
logic [0:0]                  s_axi_awlock;
logic [3:0]                  s_axi_awcache;
logic [2:0]                  s_axi_awprot;
logic [3:0]                  s_axi_awregion;
logic [3:0]                  s_axi_awqos;
logic                        s_axi_awvalid;
logic                        s_axi_awready;
logic [AxiDataWidth-1:0]     s_axi_wdata;
logic [AxiDataWidth/8-1:0]   s_axi_wstrb;
logic                        s_axi_wlast;
logic                        s_axi_wvalid;
logic                        s_axi_wready;
logic [AxiIdWidthSlaves-1:0] s_axi_bid;
logic [1:0]                  s_axi_bresp;
logic                        s_axi_bvalid;
logic                        s_axi_bready;
logic [AxiIdWidthSlaves-1:0] s_axi_arid;
logic [AxiAddrWidth-1:0]     s_axi_araddr;
logic [7:0]                  s_axi_arlen;
logic [2:0]                  s_axi_arsize;
logic [1:0]                  s_axi_arburst;
logic [0:0]                  s_axi_arlock;
logic [3:0]                  s_axi_arcache;
logic [2:0]                  s_axi_arprot;
logic [3:0]                  s_axi_arregion;
logic [3:0]                  s_axi_arqos;
logic                        s_axi_arvalid;
logic                        s_axi_arready;
logic [AxiIdWidthSlaves-1:0] s_axi_rid;
logic [AxiDataWidth-1:0]     s_axi_rdata;
logic [1:0]                  s_axi_rresp;
logic                        s_axi_rlast;
logic                        s_axi_rvalid;
logic                        s_axi_rready;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     )
) dram();

axi_riscv_atomics_wrap #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
    .AXI_DATA_WIDTH ( AxiDataWidth     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AxiUserWidth     ),
    .AXI_MAX_WRITE_TXNS ( 1  ),
    .RISCV_WORD_WIDTH   ( 64 )
) i_axi_riscv_atomics (
    .clk_i  ( clk                      ),
    .rst_ni ( ndmreset_n               ),
    .slv    ( master[ariane_soc::DRAM] ),
    .mst    ( dram                     )
);


assign dram.r_user = '0;
assign dram.b_user = '0;

//xlnx_axi_clock_converter i_xlnx_axi_clock_converter_ddr (
//  .s_axi_aclk     ( clk              ),
//  .s_axi_aresetn  ( ndmreset_n       ),
//  .s_axi_awid     ( dram.aw_id       ),
//  .s_axi_awaddr   ( dram.aw_addr     ),
//  .s_axi_awlen    ( dram.aw_len      ),
//  .s_axi_awsize   ( dram.aw_size     ),
//  .s_axi_awburst  ( dram.aw_burst    ),
//  .s_axi_awlock   ( dram.aw_lock     ),
//  .s_axi_awcache  ( dram.aw_cache    ),
//  .s_axi_awprot   ( dram.aw_prot     ),
//  .s_axi_awregion ( dram.aw_region   ),
//  .s_axi_awqos    ( dram.aw_qos      ),
//  .s_axi_awvalid  ( dram.aw_valid    ),
//  .s_axi_awready  ( dram.aw_ready    ),
//  .s_axi_wdata    ( dram.w_data      ),
//  .s_axi_wstrb    ( dram.w_strb      ),
//  .s_axi_wlast    ( dram.w_last      ),
//  .s_axi_wvalid   ( dram.w_valid     ),
//  .s_axi_wready   ( dram.w_ready     ),
//  .s_axi_bid      ( dram.b_id        ),
//  .s_axi_bresp    ( dram.b_resp      ),
//  .s_axi_bvalid   ( dram.b_valid     ),
//  .s_axi_bready   ( dram.b_ready     ),
//  .s_axi_arid     ( dram.ar_id       ),
//  .s_axi_araddr   ( dram.ar_addr     ),
//  .s_axi_arlen    ( dram.ar_len      ),
//  .s_axi_arsize   ( dram.ar_size     ),
//  .s_axi_arburst  ( dram.ar_burst    ),
//  .s_axi_arlock   ( dram.ar_lock     ),
//  .s_axi_arcache  ( dram.ar_cache    ),
//  .s_axi_arprot   ( dram.ar_prot     ),
//  .s_axi_arregion ( dram.ar_region   ),
//  .s_axi_arqos    ( dram.ar_qos      ),
//  .s_axi_arvalid  ( dram.ar_valid    ),
//  .s_axi_arready  ( dram.ar_ready    ),
//  .s_axi_rid      ( dram.r_id        ),
//  .s_axi_rdata    ( dram.r_data      ),
//  .s_axi_rresp    ( dram.r_resp      ),
//  .s_axi_rlast    ( dram.r_last      ),
//  .s_axi_rvalid   ( dram.r_valid     ),
//  .s_axi_rready   ( dram.r_ready     ),
//  // to size converter
//  .m_axi_aclk     ( ps_clock_out    ),
//  .m_axi_aresetn  ( ndmreset_n       ),
//  .m_axi_awid     ( s_axi_awid       ),
//  .m_axi_awaddr   ( s_axi_awaddr     ),
//  .m_axi_awlen    ( s_axi_awlen      ),
//  .m_axi_awsize   ( s_axi_awsize     ),
//  .m_axi_awburst  ( s_axi_awburst    ),
//  .m_axi_awlock   ( s_axi_awlock     ),
//  .m_axi_awcache  ( s_axi_awcache    ),
//  .m_axi_awprot   ( s_axi_awprot     ),
//  .m_axi_awregion ( s_axi_awregion   ),
//  .m_axi_awqos    ( s_axi_awqos      ),
//  .m_axi_awvalid  ( s_axi_awvalid    ),
//  .m_axi_awready  ( s_axi_awready    ),
//  .m_axi_wdata    ( s_axi_wdata      ),
//  .m_axi_wstrb    ( s_axi_wstrb      ),
//  .m_axi_wlast    ( s_axi_wlast      ),
//  .m_axi_wvalid   ( s_axi_wvalid     ),
//  .m_axi_wready   ( s_axi_wready     ),
//  .m_axi_bid      ( s_axi_bid        ),
//  .m_axi_bresp    ( s_axi_bresp      ),
//  .m_axi_bvalid   ( s_axi_bvalid     ),
//  .m_axi_bready   ( s_axi_bready     ),
//  .m_axi_arid     ( s_axi_arid       ),
//  .m_axi_araddr   ( s_axi_araddr     ),
//  .m_axi_arlen    ( s_axi_arlen      ),
//  .m_axi_arsize   ( s_axi_arsize     ),
//  .m_axi_arburst  ( s_axi_arburst    ),
//  .m_axi_arlock   ( s_axi_arlock     ),
//  .m_axi_arcache  ( s_axi_arcache    ),
//  .m_axi_arprot   ( s_axi_arprot     ),
//  .m_axi_arregion ( s_axi_arregion   ),
//  .m_axi_arqos    ( s_axi_arqos      ),
//  .m_axi_arvalid  ( s_axi_arvalid    ),
//  .m_axi_arready  ( s_axi_arready    ),
//  .m_axi_rid      ( s_axi_rid        ),
//  .m_axi_rdata    ( s_axi_rdata      ),
//  .m_axi_rresp    ( s_axi_rresp      ),
//  .m_axi_rlast    ( s_axi_rlast      ),
//  .m_axi_rvalid   ( s_axi_rvalid     ),
//  .m_axi_rready   ( s_axi_rready     )
//);

xlnx_clk_gen i_xlnx_clk_gen (
  .clk_out1 ( clk           ), // 25 MHz
  .clk_out2 ( phy_tx_clk    ), // 125 MHz (for RGMII PHY)
  .clk_out3 ( eth_clk       ), // 125 MHz quadrature (90 deg phase shift)
  .clk_out4 ( sd_clk_sys    ), // 50 MHz clock
  .reset    ( cpu_reset     ),
  .locked   ( pll_locked    ),
  .clk_in1  ( clk_sys )  //125 MHz
  //.clk_in1_p( USER_SI570_P    ),
  //.clk_in1_n( USER_SI570_N    )
);



//logic          eth_rst_n ;
//logic          eth_rxck  ;
//logic          eth_rxctl ;
//logic [3:0]    eth_rxd   ;
//logic          eth_txck  ;
//logic          eth_txctl ;
//logic [3:0]    eth_txd   ;
//logic          eth_mdio  ;
//logic          eth_mdc   ;



//logic [48 : 0] saxigp0_awaddr;
//logic [48 : 0] saxigp0_araddr;


//assign saxigp0_awaddr = s_axi_awaddr[48:0] & 48'h7fff_ffff;
//assign saxigp0_araddr = s_axi_araddr[48:0] & 48'h7fff_ffff;

//xlnx_zynq_ultra_ps i_xlnx_zynq_ultra_ps (
//  .saxihpc0_fpd_aclk ( ps_clock_out     ),//: in STD_LOGIC;
//  .saxigp0_aruser    (s_axi_aruser       ),//: in STD_LOGIC;
//  .saxigp0_awuser    (s_axi_awuser       ),//: in STD_LOGIC;
//  .saxigp0_awid      ('0                 ),//: in STD_LOGIC_VECTOR ( 5 downto 0 );
//  //.saxigp0_awaddr    (s_axi_awaddr[47:0] ),//: in STD_LOGIC_VECTOR ( 48 downto 0 );
//  .saxigp0_awaddr    (saxigp0_awaddr     ),//: in STD_LOGIC_VECTOR ( 48 downto 0 );
//  .saxigp0_awlen     (s_axi_awlen        ),//: in STD_LOGIC_VECTOR ( 7 downto 0 );
//  .saxigp0_awsize    (s_axi_awsize       ),//: in STD_LOGIC_VECTOR ( 2 downto 0 );
//  .saxigp0_awburst   (s_axi_awburst      ),//: in STD_LOGIC_VECTOR ( 1 downto 0 );
//  .saxigp0_awlock    (s_axi_awlock       ),//: in STD_LOGIC;
//  .saxigp0_awcache   (s_axi_awcache      ),//: in STD_LOGIC_VECTOR ( 3 downto 0 );
//  .saxigp0_awprot    (s_axi_awprot       ),//: in STD_LOGIC_VECTOR ( 2 downto 0 );
//  .saxigp0_awvalid   (s_axi_awvalid      ),//: in STD_LOGIC;
//  .saxigp0_awready   (s_axi_awready      ),//: out STD_LOGIC;
//  .saxigp0_wdata     (s_axi_wdata        ),//: in STD_LOGIC_VECTOR ( 63 downto 0 );
//  .saxigp0_wstrb     (s_axi_wstrb        ),//: in STD_LOGIC_VECTOR ( 7 downto 0 );
//  .saxigp0_wlast     (s_axi_wlast        ),//: in STD_LOGIC;
//  .saxigp0_wvalid    (s_axi_wvalid       ),//: in STD_LOGIC;
//  .saxigp0_wready    (s_axi_wready       ),//: out STD_LOGIC;
//  .saxigp0_bid       (                   ),//: out STD_LOGIC_VECTOR ( 5 downto 0 );
//  .saxigp0_bresp     (s_axi_bresp        ),//: out STD_LOGIC_VECTOR ( 1 downto 0 );
//  .saxigp0_bvalid    (s_axi_bvalid       ),//: out STD_LOGIC;
//  .saxigp0_bready    (s_axi_bready       ),//: in STD_LOGIC;
//  .saxigp0_arid      ('0                 ),//: in STD_LOGIC_VECTOR ( 5 downto 0 );
//  //.saxigp0_araddr    (s_axi_araddr[47:0] ),//: in STD_LOGIC_VECTOR ( 48 downto 0 );
//  .saxigp0_araddr    (saxigp0_araddr ),//: in STD_LOGIC_VECTOR ( 48 downto 0 );
//  .saxigp0_arlen     (s_axi_arlen        ),//: in STD_LOGIC_VECTOR ( 7 downto 0 );
//  .saxigp0_arsize    (s_axi_arsize       ),//: in STD_LOGIC_VECTOR ( 2 downto 0 );
//  .saxigp0_arburst   (s_axi_arburst      ),//: in STD_LOGIC_VECTOR ( 1 downto 0 );
//  .saxigp0_arlock    (s_axi_arlock       ),//: in STD_LOGIC;
//  .saxigp0_arcache   (s_axi_arcache      ),//: in STD_LOGIC_VECTOR ( 3 downto 0 );
//  .saxigp0_arprot    (s_axi_arprot       ),//: in STD_LOGIC_VECTOR ( 2 downto 0 );
//  .saxigp0_arvalid   (s_axi_arvalid      ),//: in STD_LOGIC;
//  .saxigp0_arready   (s_axi_arready      ),//: out STD_LOGIC;
//  .saxigp0_rid       (                   ),//: out STD_LOGIC_VECTOR ( 5 downto 0 );
//  .saxigp0_rdata     (s_axi_rdata        ),//: out STD_LOGIC_VECTOR ( 63 downto 0 );
//  .saxigp0_rresp     (s_axi_rresp        ),//: out STD_LOGIC_VECTOR ( 1 downto 0 );
//  .saxigp0_rlast     (s_axi_rlast        ),//: out STD_LOGIC;
//  .saxigp0_rvalid    (s_axi_rvalid       ),//: out STD_LOGIC;
//  .saxigp0_rready    (s_axi_rready       ),//: in STD_LOGIC;
//  .saxigp0_awqos     (s_axi_awqos        ),//: in STD_LOGIC_VECTOR ( 3 downto 0 );
//  .saxigp0_arqos     (s_axi_arqos        ),//: in STD_LOGIC_VECTOR ( 3 downto 0 );
//  //.pl_clk0           ( ps_clock_out     )//: out STD_LOGIC
//  .pl_clk0           (      )//: out STD_LOGIC
//  );

logic [31 : 0] saxibram_awaddr;
logic [31 : 0] saxibram_araddr;


assign saxibram_awaddr = dram.aw_addr & 32'h7fff_ffff;
assign saxibram_araddr = dram.ar_addr & 32'h7fff_ffff;

xlnx_blk_mem_gen i_xlnx_blk_mem_gen (

    .rsta_busy (      ),//: OUT STD_LOGIC;
    .rstb_busy (      ),//: OUT STD_LOGIC;
    .s_aclk ( clk     ),//: IN STD_LOGIC;
    .s_aresetn (    ndmreset_n  ),//: IN STD_LOGIC;
    .s_axi_awid ( dram.aw_id       ),//: IN STD_LOGIC_VECTOR(5 DOWNTO 0);
//    .s_axi_awaddr ( dram.aw_addr     ),//: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    .s_axi_awaddr ( saxibram_awaddr     ),//: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    .s_axi_awlen ( dram.aw_len      ),//: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    .s_axi_awsize ( dram.aw_size     ),//: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    .s_axi_awburst ( dram.aw_burst    ),//: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    .s_axi_awvalid ( dram.aw_valid    ),//: IN STD_LOGIC;
    .s_axi_awready ( dram.aw_ready    ),//: OUT STD_LOGIC;
    .s_axi_wdata ( dram.w_data      ),//: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    .s_axi_wstrb ( dram.w_strb      ),//: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    .s_axi_wlast ( dram.w_last      ),//: IN STD_LOGIC;
    .s_axi_wvalid ( dram.w_valid     ),//: IN STD_LOGIC;
    .s_axi_wready ( dram.w_ready     ),//: OUT STD_LOGIC;
    .s_axi_bid ( dram.b_id        ),//: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    .s_axi_bresp ( dram.b_resp      ),//: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    .s_axi_bvalid ( dram.b_valid     ),//: OUT STD_LOGIC;
    .s_axi_bready ( dram.b_ready     ),//: IN STD_LOGIC;
    .s_axi_arid ( dram.ar_id       ),//: IN STD_LOGIC_VECTOR(5 DOWNTO 0);
//    .s_axi_araddr ( dram.ar_addr     ),//: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    .s_axi_araddr ( saxibram_araddr     ),//: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    .s_axi_arlen ( dram.ar_len      ),//: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    .s_axi_arsize ( dram.ar_size     ),//: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    .s_axi_arburst( dram.ar_burst    ),//: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    .s_axi_arvalid ( dram.ar_valid    ),//: IN STD_LOGIC;
    .s_axi_arready ( dram.ar_ready    ),//: OUT STD_LOGIC;
    .s_axi_rid ( dram.r_id        ),//: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    .s_axi_rdata ( dram.r_data      ),//: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    .s_axi_rresp ( dram.r_resp      ),//: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    .s_axi_rlast ( dram.r_last      ),//: OUT STD_LOGIC;
    .s_axi_rvalid ( dram.r_valid     ),//: OUT STD_LOGIC;
    .s_axi_rready ( dram.r_ready     )//: IN STD_LOGIC
  );

endmodule

