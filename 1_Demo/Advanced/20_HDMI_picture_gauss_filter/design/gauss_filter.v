//高斯滤波
//时钟延迟 一共延迟 3clk
module	gauss_filter
(
	input	wire			video_clk		,
	input	wire			rst_n			,
		
	//矩阵数据输入	
	input	wire	[7:0]	matrix11 		,	
	input	wire	[7:0]   matrix12 		,
	input	wire	[7:0]   matrix13 		,
	
	input	wire	[7:0]	matrix21 		,
	input	wire	[7:0]   matrix22 		,
	input	wire	[7:0]   matrix23 		,
											
	input	wire	[7:0]	matrix31 		,
	input	wire	[7:0]   matrix32 		,
	input	wire	[7:0]   matrix33 		,

	output	wire	[7:0]   gauss_filter_data	

);
/*
高斯核
| 15 32 15 |
| 32 70 32 |         sum高斯核 = 256  ->   sum/16=sum>>8
| 15 32 15 |
*/

/************************************************************
step1 每行相加	delay:1clk
************************************************************/
reg	[15:0]	line1_sum;
reg	[15:0]	line2_sum;
reg	[15:0]	line3_sum;
always@(posedge video_clk or negedge rst_n)	begin
	if(!rst_n)
	begin
		line1_sum	<=	16'd0;
        line2_sum	<=	16'd0;
        line3_sum	<=	16'd0;	
	end
	else	begin
		line1_sum	<=	matrix11*15 + matrix12*32 + matrix13*15	;
        line2_sum	<=	matrix21*32 + matrix22*70 + matrix23*32	;
        line3_sum	<=	matrix31*15 + matrix32*32 + matrix33*15	;
	end
end

/************************************************************
step2 矩阵总和 delay:1clk
************************************************************/
reg	[15:0]	data_sum;
always@(posedge video_clk or negedge rst_n)	begin
	if(!rst_n)
		data_sum	<=	16'd0;
	else
		data_sum	<=	line1_sum + line2_sum + line3_sum;
end

/************************************************************
step3 右移8位 delay:1clk
************************************************************/
//移位实现/16
reg	[7:0]	gauss_filter_reg	;	//均值

always@(posedge video_clk or negedge rst_n)	begin
	if(!rst_n)
		gauss_filter_reg	<=	8'd0;
	else
		gauss_filter_reg	<=	data_sum[15:8];	//
end

assign	gauss_filter_data	=	gauss_filter_reg	;	


endmodule