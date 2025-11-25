//FIFO测试顶层
module fifo_test_top
(
	input	wire			sys_clk			,
	input	wire			rst_n			,
		
	input	wire	[7:0]	wr_data			,
	input	wire			wr_en			,
	input	wire			rd_en			,
	
	output	wire	[8:0]	wr_water_level	,
	output	wire	[8:0]	rd_water_level	,
	
	output	wire	[7:0]	rd_data		
	
);

wire			wr_full;
wire			almost_full;


wire			rd_empty;
wire			almost_empty;

fifo_test fifo_test_inst (
  .wr_clk(sys_clk),                    // input
  .wr_rst(~rst_n),                    // input
  .wr_en(wr_en),                      // input
  .wr_data(wr_data),                  // input [7:0]
  .wr_full(wr_full),                  // output
  .wr_water_level(wr_water_level),    // output [11:0]
  .almost_full(almost_full),          // output
  
  .rd_clk(sys_clk),                    // input
  .rd_rst(~rst_n),                    // input
  .rd_en(rd_en),                      // input
  .rd_data(rd_data),                  // output [7:0]
  .rd_empty(rd_empty),                // output
  .rd_water_level(rd_water_level),    // output [11:0]
  .almost_empty(almost_empty)         // output
);


endmodule