module pll_test(
    input                               sys_clk                    ,
    output                              clkout0                    ,
    output                              clkout1                    ,
    output                              clkout2                    ,
    output                              clkout3                    ,
    output                              lock                        
   );

PLL PLL_U0 (
  .clkout0(clkout0),    // output
  .clkout1(clkout1),    // output
  .clkout2(clkout2),    // output
  .clkout3(clkout3),    // output
  .lock(lock),          // output
  .clkin1(sys_clk)       // input
);

endmodule