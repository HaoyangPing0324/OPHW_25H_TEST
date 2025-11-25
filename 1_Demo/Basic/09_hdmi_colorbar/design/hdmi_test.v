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

module hdmi_test(
    input wire        sys_clk       ,// input system clock 50MHz    

//hdmi_out 
    output       tmds_clk_p,    // TMDS 时钟通道
    output       tmds_clk_n,
    output [2:0] tmds_data_p,   // TMDS 数据通道
    output [2:0] tmds_data_n
);
                          



parameter   X_WIDTH = 4'd12;
parameter   Y_WIDTH = 4'd12;    

//MODE_1080p
    parameter V_TOTAL = 12'd1125;
    parameter V_FP = 12'd4;
    parameter V_BP = 12'd36;
    parameter V_SYNC = 12'd5;
    parameter V_ACT = 12'd1080;
    parameter H_TOTAL = 12'd2200;
    parameter H_FP = 12'd88;
    parameter H_BP = 12'd148;
    parameter H_SYNC = 12'd44;
    parameter H_ACT = 12'd1920;
    parameter HV_OFFSET = 12'd0;

	wire            			rstn_out      ;
	wire            			vs_out        ; 
	wire           	 			hs_out        ; 
	wire            			de_out        ; 
	wire [23:0] 				video_data;
    wire                        pix_clk    ;
    wire                        pix_clk_x5 ;
    wire                        cfg_clk    ;
    wire                        lock1      ;
    wire                        lock2      ;
    wire                        locked     ;
    wire                        rstn       ;
    reg  [15:0]                 rstn_1ms   ;
    wire [X_WIDTH - 1'b1:0]     act_x      ;
    wire [Y_WIDTH - 1'b1:0]     act_y      ;    
    wire                        hs         ;
    wire                        vs         ;
    wire                        de         ;

    pll_0 u_pll_0 (
      .clkout0(pix_clk),    // output
      .clkout1(cfg_clk),    // output
      .lock(lock1),          // output
      .clkin1(sys_clk)       // input
    );

   pll_1 u_pll_1 (
      .clkout0(pix_clk_x5),    // output
      .lock(lock2),          // output
      .clkin1(pix_clk)       // input
    ); 

    assign locked = lock1 & lock2 ;
    
    always @(posedge cfg_clk)
    begin
    	if(!locked)
    	    rstn_1ms <= 16'd0;
    	else
    	begin
    		if(rstn_1ms == 16'h2710)
    		    rstn_1ms <= rstn_1ms;
    		else
    		    rstn_1ms <= rstn_1ms + 1'b1;
    	end
    end
    
    assign rstn_out = (rstn_1ms == 16'h2710);

    sync_vg #(
        .X_BITS               (  X_WIDTH              ), 
        .Y_BITS               (  Y_WIDTH              ),
        .V_TOTAL              (  V_TOTAL              ),//                        
        .V_FP                 (  V_FP                 ),//                        
        .V_BP                 (  V_BP                 ),//                        
        .V_SYNC               (  V_SYNC               ),//                        
        .V_ACT                (  V_ACT                ),//                        
        .H_TOTAL              (  H_TOTAL              ),//                        
        .H_FP                 (  H_FP                 ),//                        
        .H_BP                 (  H_BP                 ),//                        
        .H_SYNC               (  H_SYNC               ),//                        
        .H_ACT                (  H_ACT                ) //                        
 
    ) sync_vg                                         
    (                                                 
        .clk                  (  pix_clk               ),//input                   clk,                                 
        .rstn                 (  rstn_out                 ),//input                   rstn,                            
        .vs_out               (  vs                   ),//output reg              vs_out,                                                                                                                                      
        .hs_out               (  hs                   ),//output reg              hs_out,            
        .de_out               (  de                   ),//output reg              de_out,             
        .x_act                (  act_x                ),//output reg [X_BITS-1:0] x_out,             
        .y_act                (  act_y                ) //output reg [Y_BITS:0]   y_out,             
    );
    
    pattern_vg #(
        .COCLOR_DEPP          (  8                    ), // Bits per channel
        .X_BITS               (  X_WIDTH              ),
        .Y_BITS               (  Y_WIDTH              ),
        .H_ACT                (  H_ACT                ),
        .V_ACT                (  V_ACT                )
    ) // Number of fractional bits for ramp pattern
    pattern_vg (
        .rstn                 (  rstn_out                 ),//input                         rstn,                                                     
        .pix_clk              (  pix_clk               ),//input                         clk_in,  
        .act_x                (  act_x                ),//input      [X_BITS-1:0]       x,   
        // input video timing
        .vs_in                (  vs                   ),//input                         vn_in                        
        .hs_in                (  hs                   ),//input                         hn_in,                           
        .de_in                (  de                   ),//input                         dn_in,
        // test pattern image output                                                    
        .vs_out               (  vs_out               ),//output reg                    vn_out,                       
        .hs_out               (  hs_out               ),//output reg                    hn_out,                       
        .de_out               (  de_out               ),//output reg                    den_out,                      
        .r_out                (  video_data[23:16]    ),//output reg [COCLOR_DEPP-1:0]  r_out,                      
        .g_out                (  video_data[15:8]     ),//output reg [COCLOR_DEPP-1:0]  g_out,                       
        .b_out                (  video_data[7:0]      ) //output reg [COCLOR_DEPP-1:0]  b_out   
    );

	dvi_transmitter_top u_dvi_transmitter(
		.pclk				  (pix_clk),           			// pixel clock
		.pclk_x5			  (pix_clk_x5),        			// pixel clock x5
		.reset_n			  (rstn_out & locked),        	// reset
    
		.video_din			  (video_data),      			// RGB888 video in
		.video_hsync		  (hs_out),    					// hsync data
		.video_vsync		  (vs_out),    					// vsync data
		.video_de			  (de_out),       				// data enable
    
		.tmds_clk_p			  (tmds_clk_p),     			// TMDS 时钟通道
		.tmds_clk_n			  (tmds_clk_n),
		.tmds_data_p		  (tmds_data_p),    			// TMDS 数据通道
		.tmds_data_n		  (tmds_data_n)
	);

endmodule
