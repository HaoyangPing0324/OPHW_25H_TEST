`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-01-29 20:31  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Revision 2.0 - File Revised By HaoyangPing_PKU
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define UD #1

module led_test(
    input          clk    /*synthesis PAP_MARK_DEBUG="1"*/,
    input          rstn   /*synthesis PAP_MARK_DEBUG="1"*/,
    
    output [3:0]   led    /*synthesis PAP_MARK_DEBUG="1"*/
);


//==============================================================================
//reg and wire

    reg [24:0] led_light_cnt    = 25'd0         ;
    reg [ 3:0] led_status       = 4'b0001  ;

//time counter
    always @(posedge clk or negedge rstn)
    begin
        if(!rstn)
            led_light_cnt <= `UD 25'd0;
        else if(led_light_cnt == 25'd24_999_999)
            led_light_cnt <= `UD 25'd0;
        else
            led_light_cnt <= `UD led_light_cnt + 25'd1; 
    end
    
//led status change
    always @(posedge clk  or negedge rstn)
    begin
        if(!rstn)
            led_status <= `UD 4'b0001;
        else if(led_light_cnt == 25'd24_999_999)
            led_status <= `UD {led_status[2:0],led_status[3]};
    end

    assign led = ~led_status;
    
endmodule
