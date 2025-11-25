`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//Copyright(C) 正点原子 2023-2033
// Revised By HaoyangPing_PKU
//
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
    
    always @(posedge pix_clk)
    begin
        vs_out <= `UD vs_in;
        hs_out <= `UD hs_in;
        de_out <= `UD de_in;
    end

    //parameter define                   
localparam PIC_WIDTH   = 12'd256;    //图片宽度
localparam PIC_HEIGHT  = 12'd256;    //图片高度
localparam PIC_X_START = (H_ACT - PIC_WIDTH) / 2;     //图片起始点横坐标
localparam PIC_Y_START = (V_ACT - PIC_HEIGHT) / 2;     //图片起始点纵坐标                      
                       
localparam BACK_COLOR  = 24'hE0FFFF; //背景色，浅蓝色

//reg define
reg   [15:0]  rom_addr  ;  //ROM地址

//wire define   
wire  [23:0]  rom_rd_data ;//ROM数据

//*****************************************************
//**                    main code
//*****************************************************
//为LCD显示区域绘制图片
always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        pixel_data <= BACK_COLOR;
    else if( (act_x >= PIC_X_START -1'b1) && (act_x < PIC_X_START + PIC_WIDTH -1'b1) 
          && (act_y >= PIC_Y_START) && (act_y < PIC_Y_START + PIC_HEIGHT) )
        pixel_data <= rom_rd_data ;  //显示图片
    else 
        pixel_data <= BACK_COLOR;        //屏幕背景色
end

//根据当前扫描点的横纵坐标为ROM地址赋值
always @(posedge pix_clk or negedge rstn) begin
    if(!rstn)
        rom_addr <= 16'd0;
    //当横纵坐标位于图片显示区域时,累加ROM地址    
    else if( (act_x >= PIC_X_START -2'd2) && (act_x < PIC_X_START + PIC_WIDTH -2'd2) 
          && (act_y >= PIC_Y_START) && (act_y < PIC_Y_START + PIC_HEIGHT) )
        rom_addr <= rom_addr + 1'b1;
    //当横纵坐标位于图片区域最后一个像素点时,ROM地址清零    
    else if((act_y >= PIC_Y_START + PIC_HEIGHT))
        rom_addr <= 16'd0;
end

//ROM：存储图片
blk_mem_gen_0 blk_mem_gen_0 (
  .addr    (rom_addr),          // input [15:0]
  .clk     (pix_clk),          // input
  .rst     (~rstn),            // input
  .rd_data (rom_rd_data)     	// output [23:0]
);
    
endmodule
