//局部二值化
//延迟4个时钟信号
module	area_bin#(
    parameter	IMG_WIDTH	=	12'd2200	,
	parameter	IMG_HEIGHT	=	12'd1125
)
(
	input	wire			video_clk		,
	input	wire			rst_n			,
    input   wire[7:0]       video_data      ,
    

	output		    [23:0] data_area_bin

);

// matrix_3x3 模块输出信号定义
wire [7:0] matrix11;  // 3x3矩阵第1行第1列
wire [7:0] matrix12;  // 3x3矩阵第1行第2列  
wire [7:0] matrix13;  // 3x3矩阵第1行第3列
wire [7:0] matrix21;  // 3x3矩阵第2行第1列
wire [7:0] matrix22;  // 3x3矩阵第2行第2列
wire [7:0] matrix23;  // 3x3矩阵第2行第3列
wire [7:0] matrix31;  // 3x3矩阵第3行第1列
wire [7:0] matrix32;  // 3x3矩阵第3行第2列
wire [7:0] matrix33;  // 3x3矩阵第3行第3列

matrix_3x3 #(
    .IMG_WIDTH  (IMG_WIDTH),      // 参数：图像宽度
    .IMG_HEIGHT (IMG_HEIGHT)       // 参数：图像高度
) u_matrix_3x3 (
    .video_clk  (video_clk), // 输入：视频时钟
    .rst_n      (rst_n),     // 输入：异步复位，低电平有效
    .video_data (video_data),  // 输入：8位像素数据 [7:0]
    
    // 3x3 矩阵输出
    .matrix11   (matrix11), // 输出：3x3矩阵第1行第1列
    .matrix12   (matrix12), // 输出：3x3矩阵第1行第2列  
    .matrix13   (matrix13), // 输出：3x3矩阵第1行第3列
    .matrix21   (matrix21), // 输出：3x3矩阵第2行第1列
    .matrix22   (matrix22), // 输出：3x3矩阵第2行第2列
    .matrix23   (matrix23), // 输出：3x3矩阵第2行第3列
    .matrix31   (matrix31), // 输出：3x3矩阵第3行第1列
    .matrix32   (matrix32), // 输出：3x3矩阵第3行第2列
    .matrix33   (matrix33)  // 输出：3x3矩阵第3行第3列
);

/************************************************************
step1 每行相加	delay:1clk
************************************************************/
reg	[9:0]	line1_sum;
reg	[9:0]	line2_sum;
reg	[9:0]	line3_sum;
always@(posedge video_clk or negedge rst_n)	begin
	if(!rst_n)
	begin
		line1_sum	<=	10'd0;
        line2_sum	<=	10'd0;
        line3_sum	<=	10'd0;	
	end
	else	begin
		line1_sum	<=	matrix11 + matrix12 + matrix13	;
        line2_sum	<=	matrix21 + matrix22 + matrix23	;
        line3_sum	<=	matrix31 + matrix32 + matrix33	;
	end
end

/************************************************************
step2 矩阵总和 delay:1clk
************************************************************/
reg	[11:0]	data_sum;
always@(posedge video_clk or negedge rst_n)	begin
	if(!rst_n)
		data_sum	<=	12'd0;
	else
		data_sum	<=	line1_sum + line2_sum + line3_sum;
end

/************************************************************
step3 求均值 /9 delay:1clk
************************************************************/
//除法转乘法   *113>>10
reg	[17:0]	thre_data	;	//均值当作阈值

always@(posedge video_clk or negedge rst_n)	begin
	if(!rst_n)
		thre_data	<=	18'd0;
	else
		thre_data	<=	data_sum * 113;	//后续要>>10
end



/************************************************************
step4 中心像素点与阈值进行比较   delay:1clk
************************************************************/
reg	bin_data;
always@(posedge video_clk or negedge rst_n)	begin
	if(!rst_n)
		bin_data	<=	1'd0;
	else	if(matrix22 >= thre_data[17:10])
		bin_data	<=	1'd1;	
	else
		bin_data	<=	1'd0;
end

assign data_area_bin = {24{bin_data}};
//assign data_area_bin = {3{matrix22}};
//调试用
//assign data_area_bin = {3{matrix22}};//全是同一个灰色
//assign data_area_bin = {3{matrix11}};//全是同一个灰色
//assign data_area_bin = {3{matrix31}};//灰度化的画面
//assign data_area_bin = {3{matrix33}};//灰度化的画面
//猜测：前面两行矩阵的数据压根没有，一直只有第三行，导致亮度高了会使值大于中间而显黑，反之显白，正好相反。
//对策：检查矩阵
//assign data_area_bin = {3{matrix21}};//同一个灰色。确实如此

endmodule