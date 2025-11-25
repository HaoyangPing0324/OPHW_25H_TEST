`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: meyesemi
// Engineer: 
// 
// Create Date:   
// Design Name:  
// Module Name:  iic_dri
// Project Name: 
// Target Devices: pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define UD #1

module i2c_eeprom_test(
    input     clk,
    input     [2:0]key,
    input     rstn,
    
    output    [3:0]led,
    output    scl,
    inout     sda
);
    wire    [2:0]btn_deb;
    btn_deb_fix #(                    
        .BTN_WIDTH   (  4'd3        ), //parameter                  BTN_WIDTH = 4'd8
        .BTN_DELAY   (20'h7_ffff    )
    ) u_btn_deb                           
    (                            
        .clk         (  clk      ),//input                      clk,
        .btn_in      (  key      ),//input      [BTN_WIDTH-1:0] btn_in,
                  
        .btn_deb_fix     (  btn_deb  ) //output reg [BTN_WIDTH-1:0] btn_deb
    );


    reg [2:0]btn_deb_reg /*synthesis PAP_MARK_DEBUG="1"*/;
    always @(posedge clk)
    begin
        btn_deb_reg <= btn_deb;
    end

    reg wr/*synthesis PAP_MARK_DEBUG="1"*/;
    always @(posedge clk)
    begin
        if(!rstn)
            wr <= 1'b1;
        else if(!btn_deb[0] && btn_deb_reg[0])
            wr <= 1'b1;
        else if(!btn_deb[1] && btn_deb_reg[1])
            wr <= 1'b0;
        else
            wr <= wr;         
    end


    reg        iic_pluse/*synthesis PAP_MARK_DEBUG="1"*/;
    always @(posedge clk)
    begin
        if(!rstn)
            iic_pluse <= 1'b0;
        else if(!btn_deb[2] && btn_deb_reg[2])
            iic_pluse <= 1'b1;
        else
            iic_pluse <= 1'b0;
    end

    
    wire          busy/*synthesis PAP_MARK_DEBUG="1"*/;
    wire          byteover/*synthesis PAP_MARK_DEBUG="1"*/;
    wire [7:0]    data_out/*synthesis PAP_MARK_DEBUG="1"*/;
    wire          sda_in;     
    wire          sda_out;
    wire          sda_out_en/*synthesis PAP_MARK_DEBUG="1"*/;  

    iic_dri #(
        .CLK_FRE      (  27'd50_000_000  ),//parameter            CLK_FRE = 27'd50_000_000,
        .IIC_FREQ     (  20'd400_000     ),//parameter            IIC_FREQ = 20'd400_000,
        .T_WR         (  10'd5           ),//parameter            T_WR = 10'd5,
        .DEVICE_ID    (  8'hA0           ),//parameter            DEVICE_ID = 8'hA0,
        .ADDR_BYTE    (  2'd1            ),//parameter            ADDR_BYTE = 2'd1,
        .LEN_WIDTH    (  8'd8            ),//parameter            LEN_WIDTH = 8'd3,
        .DATA_BYTE    (  2'd1            ) //parameter            DATA_BYTE = 2'd1
    )iic_dri(                       
        .clk          (  clk             ),//input                clk,
        .rstn         (  rstn            ),//input                rstn,
        .pluse        (  iic_pluse       ),//input                pluse,
        .w_r          (  wr            ),//input                w_r,
        .byte_len     (  8'd8            ),//input  [LEN_WIDTH:0] byte_len,
                                         
        .addr         (  8'd0            ),//input  [7:0]         addr,
        .data_in      (  8'b10101010           ),//input  [7:0]         data_in,
                                         
        .busy         (  busy            ),//output reg           busy=0,
        .byte_over    (  byte_over       ),//output reg           byte_over=0,
                                         
        .data_out     (  data_out        ),//output reg[7:0]      data_out,
                  
        .scl          (  scl             ),//output               scl,
        .sda_in       (  sda_in          ),//input                sda_in,               
        .sda_out      (  sda_out         ),//output   reg         sda_out=1'b1,          
        .sda_out_en   (  sda_out_en      ) //output               sda_out_en                
    );

GTP_IOBUF #(
    .IOSTANDARD("DEFAULT"),
    .SLEW_RATE("SLOW"),
    .DRIVE_STRENGTH("8"),
    .TERM_DDR("ON")
) iobuf (
    .IO(sda),// INOUT  
    .O(sda_in), // OUTPUT  
    .I(sda_out), // INPUT  
    .T(~sda_out_en)  // INPUT  
);

assign led=~data_out[3:0];

endmodule
