`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//Author: HaoyangPing_PKU
//////////////////////////////////////////////////////////////////////////////////
`define UD #1
module video_display # (
    parameter                            COCLOR_DEPP=8, // number of bits per channel
    parameter                            X_BITS=12,
    parameter                            Y_BITS=12,
    parameter                            H_ACT = 12'd1280,
    parameter                            V_ACT = 12'd720
)(                                       
    input                                rstn, 
    input                                pix_clk,
    input [X_BITS-1:0]                   act_x,
	input [Y_BITS-1:0]                   act_y,
    input                                vs_in, 
    input                                hs_in, 
    input                                de_in,
    
    output reg                           vs_out, 
    output reg                           hs_out, 
    output reg                           de_out,
    output reg [3*COCLOR_DEPP-1:0]       pixel_data 
);

    //parameter define     
//灰度化 3 clk
//二值化 3+1 clk
//局部二值化 3+6 clk
//二值化+腐蚀/膨胀 4+2+2 clks
//局部二值化+腐蚀/膨胀 9+2+2 clks
//13 CLKS
localparam NUMBER_OF_DELAYED_CLKS_PREVIOUS = 4'd13 ;
localparam NUMBER_OF_DELAYED_CLKS_GREY = 4'd10 ;
localparam NUMBER_OF_DELAYED_CLKS_BIN = 4'd9 ;
localparam NUMBER_OF_DELAYED_CLKS_AREA_BIN = 4'd4 ;
localparam NUMBER_OF_DELAYED_CLKS_BIN_REO_DIL = 4'd5 ;

// 定义 NUMBER_OF_DELAYED_CLKS 参数数组
localparam [3:0] NUMBER_OF_DELAYED_CLKS_ARRAY [0:5] = {
    NUMBER_OF_DELAYED_CLKS_PREVIOUS,  // previous
    NUMBER_OF_DELAYED_CLKS_GREY,  // grey
    NUMBER_OF_DELAYED_CLKS_BIN,  // bin
    NUMBER_OF_DELAYED_CLKS_AREA_BIN,  // area_bin
    NUMBER_OF_DELAYED_CLKS_BIN_REO_DIL,  // bin_dil
    NUMBER_OF_DELAYED_CLKS_BIN_REO_DIL  // bin_ero
};
	
localparam PIC_WIDTH   = 12'd256;    //图片宽度
localparam PIC_HEIGHT  = 12'd256;    //图片高度

localparam PIC_X_START_COL1 = 12'd256;     //图片起始点横坐标
localparam PIC_X_START_COL2 = 12'd640;
localparam PIC_X_START_COL3 = 12'd1024;
localparam PIC_X_START_COL4 = 12'd1408;

localparam PIC_Y_START_ROW1 = 12'd220;     //图片起始点纵坐标
localparam PIC_Y_START_ROW2 = 12'd604;                     
                       
localparam BACK_COLOR  = 24'hE0FFFF; //背景色，浅蓝色
//localparam BACK_COLOR  = 24'hFF0000; //背景色，红色，调试检查问题用

localparam [11:0] PIC_X_START [0:7] = {
    PIC_X_START_COL1,   // rom_addr_previous
    PIC_X_START_COL1,   // rom_addr_grey  
    PIC_X_START_COL2,   // rom_addr_bin
    PIC_X_START_COL2,   // rom_addr_area_bin
    PIC_X_START_COL3,   // rom_addr_bin_dil
    PIC_X_START_COL4,   // rom_addr_bin_ero
    PIC_X_START_COL3,   // rom_addr_area_bin_dil
    PIC_X_START_COL4    // rom_addr_area_bin_ero
};

localparam [11:0] PIC_Y_START [0:7] = {
    PIC_Y_START_ROW1,    // rom_addr_previous
    PIC_Y_START_ROW2,    // rom_addr_grey
    PIC_Y_START_ROW1,   // rom_addr_bin
    PIC_Y_START_ROW2,   // rom_addr_area_bin
    PIC_Y_START_ROW1,   // rom_addr_bin_dil
    PIC_Y_START_ROW1,   // rom_addr_bin_ero
    PIC_Y_START_ROW2,   // rom_addr_area_bin_dil
    PIC_Y_START_ROW2    // rom_addr_area_bin_ero
};

//reg define
reg   [15:0]  rom_addr  ;  //ROM地址

// 定义rom_addr寄存器数组
reg [15:0] rom_addr_array [0:7];

//wire define 
// 为每个寄存器起别名，保持与原变量名兼容
wire [15:0] rom_addr_previous  = rom_addr_array[0];
wire [15:0] rom_addr_grey      = rom_addr_array[1];
wire [15:0] rom_addr_bin       = rom_addr_array[2];
wire [15:0] rom_addr_area_bin  = rom_addr_array[3];
wire [15:0] rom_addr_bin_dil   = rom_addr_array[4];
wire [15:0] rom_addr_bin_ero   = rom_addr_array[5];
wire [15:0] rom_addr_area_bin_dil = rom_addr_array[6];
wire [15:0] rom_addr_area_bin_ero = rom_addr_array[7];

wire vs_out0;
wire hs_out0;
wire de_out0;  

wire  [23:0]  rom_rd_data ;//ROM数据

wire [23:0] data_previous;

wire [23:0] data_area_bin_dil;
wire [23:0] data_area_bin_ero;

wire [23:0] data_grey;
wire [23:0] data_bin;
wire [23:0] data_area_bin;
wire [23:0] data_bin_dil;
wire [23:0] data_bin_ero;

wire [23:0] data_grey_d;
wire [23:0] data_bin_d;
wire [23:0] data_area_bin_d;
wire [23:0] data_bin_dil_d;
wire [23:0] data_bin_ero_d;

// 定义 data_in 和 data_out 信号数组
wire [23:0] data_in_array [0:5];
wire [23:0] data_out_array [0:5];

// 为信号数组元素起别名
assign data_in_array[0] = rom_rd_data;
assign data_in_array[1] = data_grey;
assign data_in_array[2] = data_bin;
assign data_in_array[3] = data_area_bin;
assign data_in_array[4] = data_bin_dil;
assign data_in_array[5] = data_bin_ero;

assign data_previous = data_out_array[0];
assign data_grey_d = data_out_array[1];
assign data_bin_d = data_out_array[2];
assign data_area_bin_d = data_out_array[3];
assign data_bin_dil_d = data_out_array[4];
assign data_bin_ero_d = data_out_array[5];

wire matrix_bin[0:8];
wire matrix_area_bin[0:8];
//*****************************************************
//**                    main code
//*****************************************************
//为LCD显示区域绘制图片
always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        pixel_data <= BACK_COLOR;
    else if( (act_x >= PIC_X_START[0] -1'b1) && (act_x < PIC_X_START[0] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[0]) && (act_y < PIC_Y_START[0] + PIC_HEIGHT) )
        pixel_data <= data_previous ;  //显示原图片
	else if( (act_x >= PIC_X_START[1] -1'b1) && (act_x < PIC_X_START[1] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[1]) && (act_y < PIC_Y_START[1] + PIC_HEIGHT) )
        pixel_data <= data_grey_d ;  //显示灰度化图片
	else if( (act_x >= PIC_X_START[2] -1'b1) && (act_x < PIC_X_START[2] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[2]) && (act_y < PIC_Y_START[2] + PIC_HEIGHT) )
        pixel_data <= data_bin_d ;  //显示二值化图片
	else if( (act_x >= PIC_X_START[3] -1'b1) && (act_x < PIC_X_START[3] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[3]) && (act_y < PIC_Y_START[3] + PIC_HEIGHT) )
        pixel_data <= data_area_bin_d ;  //显示局部二值化图片
	else if( (act_x >= PIC_X_START[4] -1'b1) && (act_x < PIC_X_START[4] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[4]) && (act_y < PIC_Y_START[4] + PIC_HEIGHT) )
        pixel_data <= data_bin_dil_d ;  //显示二值化膨胀图片
	else if( (act_x >= PIC_X_START[5] -1'b1) && (act_x < PIC_X_START[5] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[5]) && (act_y < PIC_Y_START[5] + PIC_HEIGHT) )
        pixel_data <= data_bin_ero_d ;  //显示二值化腐蚀图片
	else if( (act_x >= PIC_X_START[6] -1'b1) && (act_x < PIC_X_START[6] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[6]) && (act_y < PIC_Y_START[6] + PIC_HEIGHT) )
        pixel_data <= data_area_bin_dil ;  //显示局部二值化膨胀图片
	else if( (act_x >= PIC_X_START[7] -1'b1) && (act_x < PIC_X_START[7] + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START[7]) && (act_y < PIC_Y_START[7] + PIC_HEIGHT) )
        pixel_data <= data_area_bin_ero ;  //显示局部二值化腐蚀图片
    else
        pixel_data <= BACK_COLOR;        //屏幕背景色
//调试用
//pixel_data <= data_after_area_bin ;  //局部二值化后图片
end


always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        rom_addr <= 16'd0;		
	else if( (act_x >= PIC_X_START[0] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[0] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[0]) && (act_y < PIC_Y_START[0] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[0];  //显示原图片
	else if( (act_x >= PIC_X_START[1] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[1] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[1]) && (act_y < PIC_Y_START[1] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[1] ;  //显示灰度化图片
	else if( (act_x >= PIC_X_START[2] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[2] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[2]) && (act_y < PIC_Y_START[2] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[2];  //显示二值化图片
	else if( (act_x >= PIC_X_START[3] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[3] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[3]) && (act_y < PIC_Y_START[3] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[3] ;  //显示局部二值化图片
	else if( (act_x >= PIC_X_START[4] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[4] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[4]) && (act_y < PIC_Y_START[4] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[4] ;  //显示二值化膨胀图片
	else if( (act_x >= PIC_X_START[5] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[5] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[5]) && (act_y < PIC_Y_START[5] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[5] ;  //显示二值化腐蚀图片
	else if( (act_x >= PIC_X_START[6] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[6] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[6]) && (act_y < PIC_Y_START[6] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[6] ;  //显示局部二值化膨胀图片
	else if( (act_x >= PIC_X_START[7] -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START[7] + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START[7]) && (act_y < PIC_Y_START[7] + PIC_HEIGHT) )
        rom_addr <= rom_addr_array[7] ;  //显示局部二值化腐蚀图片	
    else
        rom_addr <= 16'd0;        //屏幕背景色
end

/*
创建一个数组，用genvar和generate简化代码的书写，实现例化和相关重复语句。
首先是rom_addr_数组的赋值，包括rom_addr_开头的变量，不同变量对应的PIC_X_START和PIC_Y_START不同，也列一个数组；模板为
always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr_ <= 16'd0;
    //当横纵坐标位于图片显示区域时,累加ROM地址    
    else if( (act_x >= PIC_X_START -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS ) && (act_x < PIC_X_START + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START) && (act_y < PIC_Y_START + PIC_HEIGHT) )
        rom_addr_ <= rom_addr_ + 1'b1;
    //当横纵坐标位于图片区域最后一个像素点时,ROM地址清零    
    else if((act_y >= PIC_Y_START + PIC_HEIGHT))
        rom_addr_ <= 16'd0;
end
 使用generate生成多个always块
*/
//根据当前扫描点的横纵坐标为ROM地址赋值
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : rom_addr_generate
		//根据当前扫描点的横纵坐标为ROM地址赋值
        always @(posedge pix_clk or negedge rstn) begin
            if(!rstn)
                rom_addr_array[i] <= 16'd0;
            // 当横纵坐标位于图片显示区域时,累加ROM地址
            else if( (act_x >= PIC_X_START[i] - 2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS) && 
                     (act_x < PIC_X_START[i] + PIC_WIDTH - 2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS) && 
                     (act_y >= PIC_Y_START[i]) && 
                     (act_y < PIC_Y_START[i] + PIC_HEIGHT) )
                rom_addr_array[i] <= rom_addr_array[i] + 1'b1;
            // 当横纵坐标位于图片区域最后一个像素点时,ROM地址清零
            else if((act_y >= PIC_Y_START[i] + PIC_HEIGHT))
                rom_addr_array[i] <= 16'd0;
        end
    end
endgenerate

//ROM：存储图片
blk_mem_gen_0 blk_mem_gen_0 (
  .addr    (rom_addr),          // input [15:0]
  .clk     (pix_clk),          // input
  .rst     (~rstn),            // input
  .rd_data (rom_rd_data)     	// output [23:0]
);

//图片处理
//灰度化
RGB2YCbCr u_RGB2YCbCr (
    .clk          (pix_clk),           // 输入：模块时钟
    .rst_n        (rstn),         // 输入：异步复位，低电平有效
    .img_data_in  (rom_rd_data),   // 输入：24位RGB数据输入 [23:0]
    .data_ycbcr   (data_grey) // 输出：24位YCbCr数据输出 [23:0]
);

//二值化
binarization u_binarization (
    .clk     (pix_clk),          // 输入：时钟信号
    .rst_n   (rstn),        // 输入：异步复位，低电平有效
    .y_in    (data_grey[7:0]),    // 输入：8位Y亮度数据 [7:0]
    .data_bin     (data_bin)    // 输出：二值化像素结果
);

//局部二值化
area_bin#(
    	.IMG_WIDTH(12'd2200)	,
		.IMG_HEIGHT(12'd1125)
)u_area_bin
(
    .video_clk      (pix_clk),     // 输入：视频时钟
    .rst_n          (rstn),         // 输入：异步复位，低电平有效
    .video_data (data_grey[7:0]),  // 输入：8位像素数据 [7:0]
    
    .data_area_bin  (data_area_bin) // 输出：区域二值化结果
);

// matrix_3x3_1bit 例化
matrix_3x3_1bit u_matrix_3x3_1bit_bin (
    .video_clk (pix_clk),
    .rst_n     (rstn),
    .video_data(data_bin[0]),
    .matrix11  (matrix_bin[0]),
    .matrix12  (matrix_bin[1]),
    .matrix13  (matrix_bin[2]),
    .matrix21  (matrix_bin[3]),
    .matrix22  (matrix_bin[4]),
    .matrix23  (matrix_bin[5]),
    .matrix31  (matrix_bin[6]),
    .matrix32  (matrix_bin[7]),
    .matrix33  (matrix_bin[8])
);

matrix_3x3_1bit u_matrix_3x3_1bit_area_bin (
    .video_clk (pix_clk),
    .rst_n     (rstn),
    .video_data(data_area_bin[0]),
    .matrix11  (matrix_area_bin[0]),
    .matrix12  (matrix_area_bin[1]),
    .matrix13  (matrix_area_bin[2]),
    .matrix21  (matrix_area_bin[3]),
    .matrix22  (matrix_area_bin[4]),
    .matrix23  (matrix_area_bin[5]),
    .matrix31  (matrix_area_bin[6]),
    .matrix32  (matrix_area_bin[7]),
    .matrix33  (matrix_area_bin[8])
);

// dilate 
//二值化膨胀
dilate u_dilate_bin (
    .video_clk   (pix_clk),
    .rst_n       (rstn),
    .bin_data_11 (matrix_bin[0]),
    .bin_data_12 (matrix_bin[1]),
    .bin_data_13 (matrix_bin[2]),
    .bin_data_21 (matrix_bin[3]),
    .bin_data_22 (matrix_bin[4]),
    .bin_data_23 (matrix_bin[5]),
    .bin_data_31 (matrix_bin[6]),
    .bin_data_32 (matrix_bin[7]),
    .bin_data_33 (matrix_bin[8]),
    .data_bin_dil (data_bin_dil)
);

//局部二值化膨胀
dilate u_dilate_area_bin (
    .video_clk   (pix_clk),
    .rst_n       (rstn),
    .bin_data_11 (matrix_area_bin[0]),
    .bin_data_12 (matrix_area_bin[1]),
    .bin_data_13 (matrix_area_bin[2]),
    .bin_data_21 (matrix_area_bin[3]),
    .bin_data_22 (matrix_area_bin[4]),
    .bin_data_23 (matrix_area_bin[5]),
    .bin_data_31 (matrix_area_bin[6]),
    .bin_data_32 (matrix_area_bin[7]),
    .bin_data_33 (matrix_area_bin[8]),
    .data_bin_dil (data_area_bin_dil)
);

// erosion 
//二值化腐蚀
erosion u_erosion_bin (
    .video_clk   (pix_clk),
    .rst_n       (rstn),
    .bin_data_11 (matrix_bin[0]),
    .bin_data_12 (matrix_bin[1]),
    .bin_data_13 (matrix_bin[2]),
    .bin_data_21 (matrix_bin[3]),
    .bin_data_22 (matrix_bin[4]),
    .bin_data_23 (matrix_bin[5]),
    .bin_data_31 (matrix_bin[6]),
    .bin_data_32 (matrix_bin[7]),
    .bin_data_33 (matrix_bin[8]),
    .data_bin_ero (data_bin_ero)
);

//局部二值化腐蚀
erosion u_erosion_area_bin (
    .video_clk   (pix_clk),
    .rst_n       (rstn),
    .bin_data_11 (matrix_area_bin[0]),
    .bin_data_12 (matrix_area_bin[1]),
    .bin_data_13 (matrix_area_bin[2]),
    .bin_data_21 (matrix_area_bin[3]),
    .bin_data_22 (matrix_area_bin[4]),
    .bin_data_23 (matrix_area_bin[5]),
    .bin_data_31 (matrix_area_bin[6]),
    .bin_data_32 (matrix_area_bin[7]),
    .bin_data_33 (matrix_area_bin[8]),
    .data_bin_ero (data_area_bin_ero)
);

// 实例化同步信号延迟模块
signal_delay #(
    .NUMBER_OF_DELAYED_CLKS (NUMBER_OF_DELAYED_CLKS_PREVIOUS)
) u_signal_delay (
    .rstn     (rstn),
    .clk      (pix_clk),
    .vs_in    (vs_in),
    .hs_in    (hs_in),
    .de_in    (de_in),
    .vs_out   (vs_out0),
    .hs_out   (hs_out0),
    .de_out   (de_out0)
);

    always @(posedge pix_clk)//本模块自带的一个时钟延迟
    begin
        vs_out <= `UD vs_out0;
        hs_out <= `UD hs_out0;
        de_out <= `UD de_out0;
    end

	
/*首先是NUMBER_OF_DELAYED_CLKS数组的赋值，包括NUMBER_OF_DELAYED_CLKS_开头的变量，然后是[23:0]data_in和[23:0]data_out；一共七组。模板为
data_delay #(
    .NUMBER_OF_DELAYED_CLKS (NUMBER_OF_DELAYED_CLKS),
    .COCLOR_DEPP            (COCLOR_DEPP)
) u_data_delay_previous (
    .rstn     (rstn),
    .clk      (pix_clk),
    .data_in  (data_in),
    .data_out (data_out)
);
注意例化的实体名不能一样，还有genvar i已经用过了，不能二次使用
*/

// 实例化数据信号延迟模块
genvar k;
generate
    for (k = 0; k < 6; k = k + 1) begin : data_delay_gen
        data_delay #(
            .NUMBER_OF_DELAYED_CLKS (NUMBER_OF_DELAYED_CLKS_ARRAY[k]),
            .COCLOR_DEPP            (COCLOR_DEPP)
        ) u_data_delay_inst (
            .rstn     (rstn),
            .clk      (pix_clk),
            .data_in  (data_in_array[k]),
            .data_out (data_out_array[k])
        );
    end
endgenerate

endmodule
