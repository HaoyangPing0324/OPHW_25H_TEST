`timescale 1ns / 1ps
module    PLL_tb();
reg                                        sys_clk                    ;
wire                                       clkout0                    ;
wire                                       clkout1                    ;
wire                                       clkout2                    ;
wire                                       clkout3                    ;
wire                                       lock                       ;



initial
    begin
        #2                                             
                sys_clk <= 0     ;                          
    end                                                
                                                       
parameter   CLK_FREQ = 50;//Mhz                       
always # ( 1000/CLK_FREQ/2 ) sys_clk = ~sys_clk ;              
                                                           
                                                           
pll_test u_pll_test(
    .sys_clk                            (sys_clk                   ),
    .clkout0                            (clkout0                   ),
    .clkout1                            (clkout1                   ),
    .clkout2                            (clkout2                   ),
    .clkout3                            (clkout3                   ),
    .lock                               (lock                      )
);




endmodule                                                  
