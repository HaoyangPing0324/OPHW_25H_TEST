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
localparam NUMBER_OF_DELAYED_CLKS_PREVIOUS = 9 ;
localparam NUMBER_OF_DELAYED_CLKS_GREY = 6 ;
localparam NUMBER_OF_DELAYED_CLKS_BIN = 5 ;
	
localparam PIC_WIDTH   = 12'd256;    //图片宽度
localparam PIC_HEIGHT  = 12'd256;    //图片高度
localparam PIC_X_START = 12'd256;     //图片起始点横坐标
localparam PIC_Y_START = 12'd412;     //图片起始点纵坐标

localparam PIC_WIDTH_GREY   = 12'd256;    //图片宽度
localparam PIC_HEIGHT_GREY  = 12'd256;    //图片高度
localparam PIC_X_START_GREY = 12'd640;     //图片起始点横坐标
localparam PIC_Y_START_GREY = 12'd412;     //图片起始点纵坐标

localparam PIC_WIDTH_BIN   = 12'd256;    //图片宽度
localparam PIC_HEIGHT_BIN  = 12'd256;    //图片高度
localparam PIC_X_START_BIN = 12'd1024;     //图片起始点横坐标
localparam PIC_Y_START_BIN = 12'd412;     //图片起始点纵坐标 

localparam PIC_WIDTH_AREA_BIN   = 12'd256;    //图片宽度
localparam PIC_HEIGHT_AREA_BIN  = 12'd256;    //图片高度
//localparam PIC_X_START_AREA_BIN = 12'd10;     //图片起始点横坐标
//localparam PIC_Y_START_AREA_BIN = 12'd10;     //图片起始点纵坐标 
localparam PIC_X_START_AREA_BIN = 12'd1408;     //图片起始点横坐标
localparam PIC_Y_START_AREA_BIN = 12'd412;     //图片起始点纵坐标 
                       
                       
localparam BACK_COLOR  = 24'hE0FFFF; //背景色，浅蓝色
//localparam BACK_COLOR  = 24'hFF0000; //背景色，红色，调试检查问题用

//reg define
reg   [15:0]  rom_addr  ;  //ROM地址
reg   [15:0]  rom_addr_previous  ;  //ROM地址
reg   [15:0]  rom_addr_grey  ;  //ROM地址
reg   [15:0]  rom_addr_bin  ;  //ROM地址
reg   [15:0]  rom_addr_area_bin  ;  //ROM地址

//wire define 
wire vs_out0;
wire hs_out0;
wire de_out0;  

wire  [23:0]  rom_rd_data ;//ROM数据

wire [23:0] data_previous;
wire [23:0] data_after_grey;
wire [23:0] data_after_bin;
wire [23:0] data_after_grey_d;
wire [23:0] data_after_bin_d;
wire [23:0] data_after_area_bin;



//*****************************************************
//**                    main code
//*****************************************************
//为LCD显示区域绘制图片
always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        pixel_data <= BACK_COLOR;
    else if( (act_x >= PIC_X_START -1'b1) && (act_x < PIC_X_START + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START) && (act_y < PIC_Y_START + PIC_HEIGHT) )
        pixel_data <= data_previous ;  //显示原图片
    else if( (act_x >= PIC_X_START_GREY -1'b1) && (act_x < PIC_X_START_GREY + PIC_WIDTH_GREY -1'b1) 
          && (act_y >= PIC_Y_START_GREY) && (act_y < PIC_Y_START_GREY + PIC_HEIGHT_GREY) )
        pixel_data <= data_after_grey_d ;  //灰度化后图片
    else if( (act_x >= PIC_X_START_BIN -1'b1) && (act_x < PIC_X_START_BIN + PIC_WIDTH_BIN -1'b1) 
          && (act_y >= PIC_Y_START_BIN) && (act_y < PIC_Y_START_BIN + PIC_HEIGHT_BIN) )
        pixel_data <= data_after_bin_d ;  //二值化后图片
    else if( (act_x >= PIC_X_START_AREA_BIN -1'b1) && (act_x < PIC_X_START_AREA_BIN + PIC_WIDTH_AREA_BIN -1'b1) 
          && (act_y >= PIC_Y_START_AREA_BIN) && (act_y < PIC_Y_START_AREA_BIN + PIC_HEIGHT_AREA_BIN) )
        //pixel_data <= data_after_bin_d ;  //二值化后图片
        pixel_data <= data_after_area_bin ;  //局部二值化后图片
    else
        pixel_data <= BACK_COLOR;        //屏幕背景色
//调试用
//pixel_data <= data_after_area_bin ;  //局部二值化后图片
end

always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        rom_addr <= 16'd0;
    else if( (act_x >= PIC_X_START -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS ) && (act_x < PIC_X_START + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START) && (act_y < PIC_Y_START + PIC_HEIGHT) )
        rom_addr <= rom_addr_previous;  //显示原图片
    else if( (act_x >= PIC_X_START_GREY -2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START_GREY + PIC_WIDTH_GREY  -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START_GREY) && (act_y < PIC_Y_START_GREY + PIC_HEIGHT_GREY) )
        rom_addr <= rom_addr_grey;  //灰度化后图片
    else if( (act_x >= PIC_X_START_BIN -2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS ) && (act_x < PIC_X_START_BIN + PIC_WIDTH_BIN -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START_BIN) && (act_y < PIC_Y_START_BIN + PIC_HEIGHT_BIN) )
        rom_addr <= rom_addr_bin;  //二值化后图片
    else if( (act_x >= PIC_X_START_AREA_BIN -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START_AREA_BIN + PIC_WIDTH_AREA_BIN --2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START_AREA_BIN) && (act_y < PIC_Y_START_AREA_BIN + PIC_HEIGHT_AREA_BIN) )
        rom_addr <= rom_addr_area_bin;  //局部二值化后图片
    else
        rom_addr <= 16'd0;        //屏幕背景色
end

//根据当前扫描点的横纵坐标为ROM地址赋值
always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr_previous <= 16'd0;
    //当横纵坐标位于图片显示区域时,累加ROM地址    
    else if( (act_x >= PIC_X_START -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS ) && (act_x < PIC_X_START + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START) && (act_y < PIC_Y_START + PIC_HEIGHT) )
        rom_addr_previous <= rom_addr_previous + 1'b1;
    //当横纵坐标位于图片区域最后一个像素点时,ROM地址清零    
    else if((act_y >= PIC_Y_START + PIC_HEIGHT))
        rom_addr_previous <= 16'd0;
end

always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr_grey <= 16'd0;
    //当横纵坐标位于图片显示区域时,累加ROM地址    
   else if( (act_x >= PIC_X_START_GREY -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START_GREY + PIC_WIDTH_GREY -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START_GREY) && (act_y < PIC_Y_START_GREY + PIC_HEIGHT_GREY) )
        rom_addr_grey <= rom_addr_grey + 1'b1;
    //当横纵坐标位于图片区域最后一个像素点时,ROM地址清零    
    else if((act_y >= PIC_Y_START + PIC_HEIGHT))
        rom_addr_grey <= 16'd0;
end

always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr_bin <= 16'd0;
    //当横纵坐标位于图片显示区域时,累加ROM地址    
   else if( (act_x >= PIC_X_START_BIN -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START_BIN + PIC_WIDTH_BIN -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START_BIN) && (act_y < PIC_Y_START_BIN + PIC_HEIGHT_BIN) )
        rom_addr_bin <= rom_addr_bin + 1'b1;
    //当横纵坐标位于图片区域最后一个像素点时,ROM地址清零    
    else if((act_y >= PIC_Y_START + PIC_HEIGHT))
        rom_addr_bin <= 16'd0;
end

always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr_area_bin <= 16'd0;
    //当横纵坐标位于图片显示区域时,累加ROM地址    
   else if( (act_x >= PIC_X_START_AREA_BIN -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START_AREA_BIN + PIC_WIDTH_AREA_BIN -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
          && (act_y >= PIC_Y_START_AREA_BIN) && (act_y < PIC_Y_START_AREA_BIN + PIC_HEIGHT_AREA_BIN) )
        rom_addr_area_bin <= rom_addr_area_bin + 1'b1;
    //当横纵坐标位于图片区域最后一个像素点时,ROM地址清零    
    else if((act_y >= PIC_Y_START + PIC_HEIGHT))
        rom_addr_area_bin <= 16'd0;
end

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
    .data_ycbcr   (data_after_grey) // 输出：24位YCbCr数据输出 [23:0]
);

//二值化
binarization u_binarization (
    .clk     (pix_clk),          // 输入：时钟信号
    .rst_n   (rstn),        // 输入：异步复位，低电平有效
    .y_in    (data_after_grey[7:0]),    // 输入：8位Y亮度数据 [7:0]
    .data_bin     (data_after_bin)    // 输出：二值化像素结果
);

//局部二值化
area_bin#(
    	.IMG_WIDTH(12'd2200)	,
		.IMG_HEIGHT(12'd1125)
)u_area_bin
(
    .video_clk      (pix_clk),     // 输入：视频时钟
    .rst_n          (rstn),         // 输入：异步复位，低电平有效
    .video_data (data_after_grey[7:0]),  // 输入：8位像素数据 [7:0]
    
    .data_area_bin  (data_after_area_bin) // 输出：区域二值化结果
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

// 实例化数据信号延迟模块
data_delay #(
    .NUMBER_OF_DELAYED_CLKS (NUMBER_OF_DELAYED_CLKS_PREVIOUS),
    .COCLOR_DEPP            (COCLOR_DEPP)
) u_data_delay_previous (
    .rstn     (rstn),
    .clk      (pix_clk),
    .data_in  (rom_rd_data),
    .data_out (data_previous)
);

data_delay #(
    .NUMBER_OF_DELAYED_CLKS (NUMBER_OF_DELAYED_CLKS_GREY),
    .COCLOR_DEPP            (COCLOR_DEPP)
) u_data_delay_grey (
    .rstn     (rstn),
    .clk      (pix_clk),
    .data_in  (data_after_grey),
    .data_out (data_after_grey_d)
);

data_delay #(
    .NUMBER_OF_DELAYED_CLKS (NUMBER_OF_DELAYED_CLKS_BIN),
    .COCLOR_DEPP            (COCLOR_DEPP)
) u_data_delay_bin (
    .rstn     (rstn),
    .clk      (pix_clk),
    .data_in  (data_after_bin),
    .data_out (data_after_bin_d)
);
endmodule
