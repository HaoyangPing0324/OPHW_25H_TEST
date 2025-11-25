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

module tb_led_test();

reg         clk     ;
reg         rst_n   ;
wire[3:0]   led     ;

parameter CYCLE    = 2;
parameter RST_TIME = 100 ;

led_test u_led_test(
 .clk       (clk    ),// input          
 .rstn      (rst_n  ),// input          
 .led       (led    ) // output [7:0]  
);               

initial begin
    clk = 0;
    forever
    #(CYCLE/2)
    clk=~clk;
end

initial begin
    rst_n = 1;
    #2;
    rst_n = 0;
    #(CYCLE*RST_TIME);
    rst_n = 1;
end

endmodule

