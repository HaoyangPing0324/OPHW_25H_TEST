`timescale 1ns/1ns
module fifo_test_tb();

reg	sys_clk;
reg	rst_n;

reg			[7:0]	wr_data;
reg					wr_en;
reg					rd_en;

reg					rd_state;    //读状态
reg                 wr_state;

wire		[7:0]	rd_data;
reg			[7:0]	rd_cnt;

wire		[8:0]	rd_water_level;
wire		[8:0]	wr_water_level;

initial
begin
	rst_n	<=	1'd0;
	sys_clk	<=	1'd0;
	#20
	rst_n	<=	1'd1;
	
	
end

always#10 sys_clk = ~sys_clk;    //50MHZ

always@(posedge sys_clk or negedge rst_n)	begin
	if(!rst_n)
	begin
        wr_state    <=    1'd0;
		wr_en	<=	1'd0;
		wr_data	<=	8'd0;
	end
	else  
    begin
        case(wr_state)
            1'd0:    if(wr_water_level == 127)    //128个数据
                     begin
                        wr_en    <=    #2 1'd0;
                        wr_data  <=    #2 8'd0;
                        wr_state <=    #2 1'd1;
                     end
                     else
                     begin
                        wr_en    <=    #2 1'd1;        
		                wr_data  <=    #2 wr_data+1'b1;
                        wr_state <=    #2 1'd0;
                     end

            1'd1:    if(rd_cnt == 127)
                         wr_state    <=    #2 1'd0;
            

            default:    wr_state    <=1'd0;
        endcase
    end
end

always@(posedge sys_clk or negedge rst_n)	begin
	if(!rst_n)
	begin
		rd_state<=	1'd0;
		rd_en	<=	1'd0;
		rd_cnt	<=	8'd0;
	end
	else
	begin
		case(rd_state)
			1'd0:	if(rd_water_level >= 8'd128)    //等待128个数据
                    begin
						rd_state    <=	 #2 1'd1;
                        rd_en	    <=	 #2 1'd1;
                    end
					else
                    begin
                        rd_cnt      <=  #2 8'd0;  
						rd_state	<=	#2 1'd0;
                    end
			
			1'd1:	begin
						
						rd_cnt	<=	 #2 rd_cnt + 1'b1;
						if(rd_cnt == 127)
						begin
							rd_en	    <=	#2 1'd0;
							rd_state	<=	#2 1'd0;
						end
					end
			default:	rd_state	<=	1'd0;
		endcase
	end	
end

GTP_GRS GRS_INST(
    .GRS_N(1'b1)
    ) ;

fifo_test_top u_fifo_test_top(
    .sys_clk         ( sys_clk         ),
    .rst_n           ( rst_n           ),
    .wr_data         ( wr_data         ),
    .wr_en           ( wr_en           ),
    .rd_en           ( rd_en           ),
    .wr_water_level  ( wr_water_level  ),
    .rd_water_level  ( rd_water_level  ),
    .rd_data         ( rd_data         )
);
endmodule