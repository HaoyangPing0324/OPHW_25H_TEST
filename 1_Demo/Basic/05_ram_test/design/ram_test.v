module ram_test_top
(
    input    wire               wr_clk        ,//写时钟
    input    wire               rd_clk        ,//读时钟
    input    wire               rst_n         ,//复位

    input    wire               rw_en         ,//读写使能信号
    input    wire    [5:0]      wr_addr       ,//写地址
    input    wire    [5:0]      rd_addr       ,//读地址
    input    wire    [7:0]      wr_data       ,//写数据
    
    output   wire    [7:0]      rd_data        //读数据
);


ram_test ram_test_inst (
  .wr_data(wr_data),    // input [7:0]
  .wr_addr(wr_addr),    // input [5:0]
  .wr_en(rw_en),        // input    
  .wr_clk(wr_clk),      // input
  .wr_rst(~rst_n),      // input

  .rd_addr(rd_addr),    // input [5:0]
  .rd_data(rd_data),    // output [7:0]
  .rd_clk(rd_clk),      // input
  .rd_rst(~rst_n)       // input
);



endmodule