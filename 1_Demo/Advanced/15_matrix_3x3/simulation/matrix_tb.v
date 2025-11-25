//图像矩阵仿真代码
`timescale 1ns/1ns
module	matrix_tb();

reg			clk;
reg			rst_n;
reg			video_de;
reg			video_vs;
reg	[7:0]	video_data;
reg [7:0]   cnt;
wire 	[7:0]	matrix11;
wire 	[7:0]   matrix12;
wire 	[7:0]   matrix13;		            
wire 	[7:0]	matrix21;
wire 	[7:0]   matrix22;
wire 	[7:0]   matrix23;	            
wire 	[7:0]	matrix31;
wire 	[7:0]   matrix32;
wire 	[7:0]   matrix33;

initial
begin
	clk		<=	1'd0;
	rst_n	<=	1'd0;
	video_de<=  1'd0;	
    video_vs<=  1'd0; 
 
	#20
	rst_n	<=	1'd1;

end

always#10 clk = ~clk;    //50MHZ


//产生视频数据

always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		cnt	<=	8'd0;
	else	if(cnt<8'd10)
		cnt	<=	cnt + 1'b1;
	else
		cnt	<=	8'd0;
end

always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		video_data	<=	8'd0;
	else	if(video_de && video_data<8'd100)
		video_data	<=	video_data + 1'b1;
	else	if(video_de && video_data==8'd24)
		video_data	<=	8'd0;
	else
		video_data	<=	video_data;
end

always@(posedge clk or negedge rst_n)	begin
	if(!rst_n)
		video_de	<=	1'd0;
	else	if(cnt<8'd5)
		video_de	<=	1'b1;
	else
		video_de	<=	1'd0;
end


//仿真需要改小视频大小 避免太大
//全局复位
GTP_GRS GRS_INST(
    .GRS_N(1'b1)
    ) ;
wire [7:0]video_data_in;
assign video_data_in=(video_de)? video_data: 8'd0;

matrix_3x3#(
    .IMG_WIDTH   ( 11'd5 ),
    .IMG_HEIGHT  ( 11'd5 )
)u_matrix_3x3(
    .video_clk   ( clk         ),
    .rst_n       ( rst_n       ),
    .video_vs    ( video_vs    ),
    .video_de    ( video_de    ),
    .video_data  ( video_data_in  ),
    .matrix_de   ( matrix_de   ),
    .matrix11    ( matrix11    ),
    .matrix12    ( matrix12    ),
    .matrix13    ( matrix13    ),
    .matrix21    ( matrix21    ),
    .matrix22    ( matrix22    ),
    .matrix23    ( matrix23    ),
    .matrix31    ( matrix31    ),
    .matrix32    ( matrix32    ),
    .matrix33    ( matrix33    )
);



endmodule