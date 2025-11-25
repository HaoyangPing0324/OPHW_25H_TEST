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
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define UD #1
module led(
    input         clk,//50MHz
    input  [1:0]  ctrl,
                  
    output [3:0]  led
);

    reg [24:0] led_light_cnt = 25'd0;
    reg [ 3:0] led_status = 4'b1000;
    
    //  time counter
    always @(posedge clk)
    begin
        if(led_light_cnt == 25'd24_999_999)
            led_light_cnt <= `UD 25'd0;
        else
            led_light_cnt <= `UD led_light_cnt + 25'd1; 
    end
    
    reg [1:0] ctrl_1d=0;    //保存上一个led状态周期的ctrl值
    always @(posedge clk)
    begin
        if(led_light_cnt == 25'd0)
            ctrl_1d <= ctrl;
    end

    // led status change
    always @(posedge clk)
    begin
        if(led_light_cnt == 25'd24_999_999)//0.5s 周期
        begin
            case(ctrl)
                2'd0 :  //从高位到低位的led流水灯
                begin
                    if(ctrl_1d != ctrl)
                        led_status <= `UD 4'b1000;
                    else
                        led_status <= `UD {led_status[0],led_status[3:1]};
                end
                2'd1 :  //隔一亮一交替
                begin
                    if(ctrl_1d != ctrl)
                        led_status <= `UD 4'b1010;
                    else
                        led_status <= `UD ~led_status;
                end
                2'd2 :  //从高位到低位暗灯流水
                begin
                    if(ctrl_1d != ctrl )
                        led_status <= `UD 4'b0111;
                    else
                        led_status <= `UD {led_status[0],led_status[3:1]};
                end
            endcase
        end
    end

    assign led = ~led_status;

endmodule
