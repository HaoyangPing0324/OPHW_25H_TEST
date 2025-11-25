`timescale 1ns/1ns
module rom_test_tb();
reg    sys_clk;
reg    rst_n;
reg    [9:0]    rd_addr;
wire   [63:0]    rd_data;

initial
begin
    rst_n    <=    1'd0;
    sys_clk  <=    1'd0;
    #20
    rst_n    <=    1'd1;

end


//50MHZ
always#10 sys_clk = ~sys_clk;


//
GTP_GRS GRS_INST(
    .GRS_N(1'b1)
    ) ;

always@(posedge sys_clk or negedge rst_n)    begin
    if(!rst_n)
        rd_addr    <=    10'd0;
    else    
        rd_addr    <=    #2 rd_addr + 1'b1;
end

rom_test_top u_rom_test_top(
    .rd_clk   ( sys_clk  ),
    .rst_n    ( rst_n    ),
    .rd_addr  ( rd_addr  ),
    .rd_data  ( rd_data  )
);

endmodule