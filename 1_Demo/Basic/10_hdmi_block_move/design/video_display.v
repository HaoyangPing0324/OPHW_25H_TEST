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
parameter  DIV_CNT = 22'd750000;				//分频计数器

localparam SIDE_W  = 11'd40;                    //屏幕边框宽度
localparam BLOCK_W = 11'd40;                    //方块宽度
localparam BLUE    = 24'h0000ff;    			//屏幕边框颜色 蓝色
localparam WHITE   = 24'hffffff;    			//背景颜色 白色
localparam BLACK   = 24'h000000;    			//方块颜色 黑色


//reg define
reg [10:0] block_x = SIDE_W ;                   //方块左上角横坐标
reg [10:0] block_y = SIDE_W ;                   //方块左上角纵坐标
reg [21:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：向上

//wire define   
wire move_en;                                   //方块移动使能信号，频率为100hz

//*****************************************************
//**                    main code
//*****************************************************
assign move_en = (div_cnt == DIV_CNT) ? 1'b1 : 1'b0;

//通过对div驱动时钟计数，实现时钟分频
always @(posedge pix_clk or negedge rstn) begin         
    if (!rstn)
        div_cnt <= 22'd0;
    else begin
        if(div_cnt < DIV_CNT) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;                   //计数达10ms后清零
    end
end

//当方块移动到边界时，改变移动方向
always @(posedge pix_clk or negedge rstn) begin         
    if (!rstn) begin
        h_direct <= 1'b1;                       //方块初始水平向右移动
        v_direct <= 1'b1;                       //方块初始竖直向下移动
    end
    else begin
        if(block_x == SIDE_W + 1'b1)            //到达左边界时，水平向右
            h_direct <= 1'b1;               
        else                                    //到达右边界时，水平向左
        if(block_x == H_ACT - SIDE_W - BLOCK_W + 1'b1)
            h_direct <= 1'b0;               
        else
            h_direct <= h_direct;
            
        if(block_y == SIDE_W + 1'b1)            //到达上边界时，竖直向下
            v_direct <= 1'b1;                
        else                                    //到达下边界时，竖直向上
        if(block_y == V_ACT - SIDE_W - BLOCK_W + 1'b1)
            v_direct <= 1'b0;               
        else
            v_direct <= v_direct;
    end
end

//根据方块移动方向，改变其纵横坐标
always @(posedge pix_clk or negedge rstn) begin         
    if (!rstn) begin
        block_x <= SIDE_W + 1'b1;                     //方块初始位置横坐标
        block_y <= SIDE_W + 1'b1;                     //方块初始位置纵坐标
    end
    else if(move_en) begin
        if(h_direct) 
            block_x <= block_x + 1'b1;          //方块向右移动
        else
            block_x <= block_x - 1'b1;          //方块向左移动
            
        if(v_direct) 
            block_y <= block_y + 1'b1;          //方块向下移动
        else
            block_y <= block_y - 1'b1;          //方块向上移动
    end
    else begin
        block_x <= block_x;
        block_y <= block_y;
    end
end

//给不同的区域绘制不同的颜色
always @(posedge pix_clk or negedge rstn) begin         
    if (!rstn) 
        pixel_data <= BLACK;
    else begin
        if(  (act_x < SIDE_W) || (act_x >= H_ACT - SIDE_W)
          || (act_y <= SIDE_W) || (act_y > V_ACT - SIDE_W))
            pixel_data <= BLUE;                 //绘制屏幕边框为蓝色
        else
        if(  (act_x >= block_x - 1'b1) && (act_x < block_x + BLOCK_W - 1'b1)
          && (act_y >= block_y) && (act_y < block_y + BLOCK_W))
            pixel_data <= BLACK;                //绘制方块为黑色
        else
            pixel_data <= WHITE;                //绘制背景为白色
    end
end

endmodule 