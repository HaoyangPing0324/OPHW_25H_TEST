module rom_test_top
(
    input    wire               rd_clk        ,//读时钟
    input    wire               rst_n         ,//复位



    input    wire    [9:0]      rd_addr       ,//读地址

    
    output   wire    [63:0]      rd_data        //读数据
    
   
);


rom_test rom_test_inst (
  .addr(rd_addr),          // input [9:0]
  .clk(rd_clk),            // input
  .rst(~rst_n),            // input
  .rd_data(rd_data)     // output [63:0]
);




endmodule