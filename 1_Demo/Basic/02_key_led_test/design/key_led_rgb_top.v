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
module key_led_top(
    input           clk,//50MHz
    input           key,
    
    output [3:0]    led
);

   wire [1:0] ctrl;
   
   key_ctl key_ctl(
       .clk        (  clk  ),//input            clk,
       .key        (  key  ),//input            key,
                 
       .ctrl       (  ctrl  )//output     [1:0] ctrl
   );
   
   led u_led(
       .clk   (  clk   ),//input         clk,
       .ctrl  (  ctrl  ),//input  [1:0]  ctrl,
                      
       .led   (  led   ) //output [7:0]  led
   );

endmodule
