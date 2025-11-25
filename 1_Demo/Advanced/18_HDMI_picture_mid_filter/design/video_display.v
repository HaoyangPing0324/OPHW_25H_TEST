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
//中值滤波 3clks
localparam NUMBER_OF_DELAYED_CLKS_PREVIOUS = 3 ;

localparam PIC_WIDTH   = 12'd256;    //图片宽度
localparam PIC_HEIGHT  = 12'd256;    //图片高度

localparam PIC_X_START_COL1 = 12'd640;     //图片起始点横坐标
localparam PIC_X_START_COL2 = 12'd1024;

localparam PIC_Y_START_ROW = 12'd412;     //图片起始点纵坐标                   
                       
localparam BACK_COLOR  = 24'hE0FFFF; //背景色，浅蓝色
//localparam BACK_COLOR  = 24'hFF0000; //背景色，红色，调试检查问题用

//reg define
reg   [15:0]  rom_addr  ;  //ROM地址
reg [15:0] rom_addr_previous;
reg [15:0] rom_addr_midian_filter;

//wire define
wire vs_out0;
wire hs_out0;
wire de_out0;  

wire  [23:0]  rom_rd_data ;//ROM数据

wire [23:0] data_previous;

wire [23:0] data_midian_filter;

wire [7:0] matrix11[0:2];
wire [7:0] matrix12[0:2];
wire [7:0] matrix13[0:2];
wire [7:0] matrix21[0:2];
wire [7:0] matrix22[0:2];
wire [7:0] matrix23[0:2];
wire [7:0] matrix31[0:2];
wire [7:0] matrix32[0:2];
wire [7:0] matrix33[0:2];

//*****************************************************
//**                    main code
//*****************************************************
//为LCD显示区域绘制图片
always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        pixel_data <= BACK_COLOR;
    else if( (act_x >= PIC_X_START_COL1 -1'b1) && (act_x < PIC_X_START_COL1 + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START_ROW) && (act_y < PIC_Y_START_ROW + PIC_HEIGHT) )
        pixel_data <= data_previous ;  //显示原图片
	else if( (act_x >= PIC_X_START_COL2 -1'b1) && (act_x < PIC_X_START_COL2 + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START_ROW) && (act_y < PIC_Y_START_ROW + PIC_HEIGHT) )
        pixel_data <= data_midian_filter ;  //显示中值滤波图片
    else
        pixel_data <= BACK_COLOR;        //屏幕背景色
//调试用
//pixel_data <= data_after_area_bin ;  //局部二值化后图片
end


always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        rom_addr <= 16'd0;		
	else if( (act_x >= PIC_X_START_COL1 -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START_COL1 + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
		&& (act_y >= PIC_Y_START_ROW) && (act_y < PIC_Y_START_ROW + PIC_HEIGHT) )//显示原图片
        rom_addr <= rom_addr_previous;
    else if( (act_x >= PIC_X_START_COL2 -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) && (act_x < PIC_X_START_COL2 + PIC_WIDTH -2'd2 -NUMBER_OF_DELAYED_CLKS_PREVIOUS) 
		&& (act_y >= PIC_Y_START_ROW) && (act_y < PIC_Y_START_ROW + PIC_HEIGHT) )//显示中值滤波图片
        rom_addr <= rom_addr_midian_filter; 
    else
        rom_addr <= 16'd0;        //屏幕背景色
end

//根据当前扫描点的横纵坐标为ROM地址赋值
always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr_previous <= 16'd0;
    // 当横纵坐标位于图片显示区域时,累加ROM地址
    else if( (act_x >= PIC_X_START_COL1 - 2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS) && 
             (act_x < PIC_X_START_COL1 + PIC_WIDTH - 2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS) && 
             (act_y >= PIC_Y_START_ROW) && 
             (act_y < PIC_Y_START_ROW + PIC_HEIGHT) )
        rom_addr_previous <= rom_addr_previous + 1'b1;
    // 当横纵坐标位于图片区域最后一个像素点时,ROM地址清零
    else if((act_y >= PIC_Y_START_ROW + PIC_HEIGHT))
        rom_addr_previous <= 16'd0;
end

always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr_midian_filter <= 16'd0;
    // 当横纵坐标位于图片显示区域时,累加ROM地址
    else if( (act_x >= PIC_X_START_COL2 - 2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS) && 
             (act_x < PIC_X_START_COL2 + PIC_WIDTH - 2'd2 - NUMBER_OF_DELAYED_CLKS_PREVIOUS) && 
             (act_y >= PIC_Y_START_ROW) && 
             (act_y < PIC_Y_START_ROW + PIC_HEIGHT) )
        rom_addr_midian_filter <= rom_addr_midian_filter + 1'b1;
    // 当横纵坐标位于图片区域最后一个像素点时,ROM地址清零
    else if((act_y >= PIC_Y_START_ROW + PIC_HEIGHT))
        rom_addr_midian_filter <= 16'd0;
end

//ROM：存储图片
blk_mem_gen_0 blk_mem_gen_0 (
  .addr    (rom_addr),          // input [15:0]
  .clk     (pix_clk),          // input
  .rst     (~rstn),            // input
  .rd_data (rom_rd_data)     	// output [23:0]
);

//图片处理
//中值滤波

genvar i;
generate
    for (i = 0; i <= 2; i = i + 1) begin : u_data_median_filter
        matrix_3x3 
		#(
			.IMG_WIDTH (12'd2200),
			.IMG_HEIGHT(12'd1125)
		)
		u_matrix_3x3_red
		(
			.video_clk  (pix_clk),
			.rst_n      (rstn),
			.video_data (rom_rd_data[(23 - 8 *i):(16 - 8*i)]),
			.matrix11   (matrix11[i]),
			.matrix12   (matrix12[i]),
			.matrix13   (matrix13[i]),
			.matrix21   (matrix21[i]),
			.matrix22   (matrix22[i]),
			.matrix23   (matrix23[i]),
			.matrix31   (matrix31[i]),
			.matrix32   (matrix32[i]),
			.matrix33   (matrix33[i])
		);
	
		median_filter_3x3 u_median_filter_3x3
		(
			.clk         (pix_clk),
			.rst_n       (rstn),
			.data11      (matrix11[i]),
			.data12      (matrix12[i]),
			.data13      (matrix13[i]),
			.data21      (matrix21[i]),
			.data22      (matrix22[i]),
			.data23      (matrix23[i]),
			.data31      (matrix31[i]),
			.data32      (matrix32[i]),
			.data33      (matrix33[i]),
			.target_data (data_midian_filter[(23 - 8 *i):(16 - 8*i)])
		);
    end
endgenerate

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
        ) u_data_delay_inst (
            .rstn     (rstn),
            .clk      (pix_clk),
            .data_in  (rom_rd_data),
            .data_out (data_previous)
);

endmodule
