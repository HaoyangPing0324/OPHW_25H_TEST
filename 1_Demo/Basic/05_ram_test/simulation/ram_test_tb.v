`timescale 1ns/1ns
module ram_test_tb();
reg    sys_clk;
reg    rd_clk ;
reg    rst_n;

reg    rw_en;    //读写使能信号

reg    [7:0]    wr_data;
reg    [5:0]    wr_addr;
reg    [5:0]    rd_addr;

wire   [7:0]    rd_data;

reg    [1:0]    state;

initial
begin
    rst_n    <=    1'd0;
    sys_clk  <=    1'd0;
    rd_clk   <=    1'd0;
    #20
    rst_n    <=    1'd1;

end



//读写控制
always@(posedge sys_clk or negedge rst_n)    begin
    if(!rst_n)
    begin
        state    <=    2'd0;
        wr_data  <=    8'd0;
        rw_en    <=    1'd0;
        wr_addr  <=    8'd0;
        rd_addr  <=    8'd1;
    end
    else
    begin
    case(state)
        2'd0:begin
                rw_en    <=    1'd1;
                state    <=    2'd1;
             end

        2'd1:begin
                if(wr_addr == 5'd31)    //32个数据
                begin
                    rw_en    <=    #2 1'd0;
                    state    <=    #2 2'd2;
                    wr_data  <=    #2 8'd0;
                    wr_addr  <=    #2 5'd0;
                    rd_addr  <=    #2 5'd0; 
                end
                else
                begin
                    state    <=    #2 2'd1;
                    wr_data  <=    #2 wr_data+1'b1;
                    //rd_addr  <=    #2 rd_addr+1'b1;
                    wr_addr  <=    #2 wr_addr+1'b1;
                end
             end
        2'd2:begin
                if(rd_addr == 5'd31)//读出32个
                begin
                    state    <=    #2 2'd3;
                    rd_addr  <=    #2 5'd0;
                end
                else
                begin
                    state    <=    #2 2'd2;
                    rd_addr  <=    #2 rd_addr+1'b1;
                end
             end
        2'd3:begin
                state    <=       2'd0;
             end

       default:    state    <=    2'd0;
       endcase
    end
end

//50MHZ
always#10 sys_clk = ~sys_clk;

//
GTP_GRS GRS_INST(
    .GRS_N(1'b1)
    ) ;

ram_test_top u_ram_test_top(
    .wr_clk   ( sys_clk   ),
    .rd_clk   ( sys_clk   ),
    .rst_n    ( rst_n    ),
    .rw_en    ( rw_en    ),
    .wr_addr  ( wr_addr  ),
    .rd_addr  ( rd_addr  ),
    .wr_data  ( wr_data  ),
    .rd_data  ( rd_data  )
);


//test posedge
reg    flag;
always@(posedge sys_clk or negedge rst_n)    begin
    if(!rst_n)
        flag    <=    1'd0;
    else
        flag    <=    1'd1;
end

reg    test;
always@(posedge sys_clk or negedge rst_n)    begin
    if(!rst_n)
        test    <=    1'd0;
    else    if(flag)
        test    <=    1'b1;
end

endmodule