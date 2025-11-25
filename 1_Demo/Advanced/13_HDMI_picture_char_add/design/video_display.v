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
                       
localparam CHAR_X_START= 12'd880;//PIC_X_START + (PIC_WIDTH - 32 * 5) / 2;     //字符起始点横坐标
localparam CHAR_Y_START= 12'd636;//PIC_Y_START + PIC_HEIGHT - 32;    //字符起始点纵坐标
localparam CHAR_WIDTH  = 12'd160;//32 * 5;    
localparam CHAR_HEIGHT = 12'd32;//32;     
                       
localparam BACK_COLOR  = 24'hE0FFFF; //背景色，浅蓝色
localparam CHAR_COLOR  = 24'hFF0000; //字符颜色，红色

//reg define
reg   [159:0] char[31:0];  //字符数组
reg   [15:0]  rom_addr  ;  //ROM地址

//wire define   
wire  [11:0]  x_cnt;       //横坐标计数器
wire  [11:0]  y_cnt;       //纵坐标计数器
wire  [23:0]  rom_rd_data ;//ROM数据

//*****************************************************
//**                    main code
//*****************************************************

assign  x_cnt = act_x + 1'b1  - CHAR_X_START; //像素点相对于字符区域起始点水平坐标
assign  y_cnt = act_y - CHAR_Y_START; //像素点相对于字符区域起始点垂直坐标

//给字符数组赋值，显示汉字“小眼睛科技”，每个汉字大小为32*32
always @(posedge pix_clk) begin
    char[0]  <= 160'h0000000000000000000000000000000000000000;
    char[1]  <= 160'h0000000000000000000000000000000000000000;
    char[2]  <= 160'h0000000000000000000000000000000000000000;
    char[3]  <= 160'h0000000000000000000000000000000000000000;
    char[4]  <= 160'h0000000000000000000000000000000000000000;
    char[5]  <= 160'h0000000000000000000000000000000000000000;
    char[6]  <= 160'h0000000000000000000000000000000000000000;
    char[7]  <= 160'h0000000000000000000000000000000000000000;
    char[8]  <= 160'h000180000000000000003800001C038000E03800;
    char[9]  <= 160'h0001C0000C23FFC0000038000FFC038000E03800;
    char[10] <= 160'h0001C0001FF3FFC0184FFFE007F0638000E03800;
    char[11] <= 160'h0001C0001E7381C03FEFF8000070738000E03800;
    char[12] <= 160'h0031C8001C73FFC01CE4380000703F800FFBFFE0;
    char[13] <= 160'h0031DC001C73FFC018CFFFC01FFE03801FFF3800;
    char[14] <= 160'h0061CE001FF381C018C038001FF1838000E03800;
    char[15] <= 160'h00E1C7001FF381C01FDFFFFE00F1FB8000E0FF00;
    char[16] <= 160'h01C1C7801C73FFC01FFE03FE01F0638000FD8380;
    char[17] <= 160'h03C1C3C01C73800018C3031803FC03800FF98380;
    char[18] <= 160'h0781C1F01FF300C018C3FF800774FFFE1FE1E300;
    char[19] <= 160'h1F81C0F81FF371C01FC383800E71FFFE08E0F600;
    char[20] <= 160'h7F03C0FF1C733F001FC3FF801C73C39C00E03E00;
    char[21] <= 160'h7E03C07E1C731F0018C303807870038000E01F00;
    char[22] <= 160'h1C03C03C1C739FE018C3FF807070038000E07FC0;
    char[23] <= 160'h0003C0001FF3BBFC1FE3C7800070038000EFF1FC;
    char[24] <= 160'h00E3C0001FF7F0FE1FC703800070038073FFC0FE;
    char[25] <= 160'h00FFC0000007E07E000E0380007003803FCE007C;
    char[26] <= 160'h003FC0000007803C003E038000E003800F800038;
    char[27] <= 160'h000F000000000000001801000040000000000000;
    char[28] <= 160'h0000000000000000000000000000000000000000;
    char[29] <= 160'h0000000000000000000000000000000000000000;
    char[30] <= 160'h0000000000000000000000000000000000000000;
    char[31] <= 160'h0000000000000000000000000000000000000000;
end

//为LCD显示区域绘制图片和字符
always @(posedge pix_clk or negedge rstn) begin
    if (!rstn)
        pixel_data <= BACK_COLOR;
    else if((act_x >= CHAR_X_START - 1'b1) && (act_x < CHAR_X_START + CHAR_WIDTH - 1'b1)
         && (act_y >= CHAR_Y_START) && (act_y < CHAR_Y_START + CHAR_HEIGHT) && (char[y_cnt][CHAR_WIDTH -1'b1 - x_cnt]))
            pixel_data <= CHAR_COLOR;    //显示字符
    else if( (act_x >= PIC_X_START - 1'b1) && (act_x < PIC_X_START + PIC_WIDTH - 1'b1) 
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
    else if( (act_x >= PIC_X_START - 2'd2) && (act_x < PIC_X_START + PIC_WIDTH - 2'd2) 
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
