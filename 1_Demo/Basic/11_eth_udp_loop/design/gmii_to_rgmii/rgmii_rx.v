//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           rgmii_rx
// Last modified Date:  2020/2/13 9:20:14
// Last Version:        V1.0
// Descriptions:        RGMII接收模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/13 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module rgmii_rx(
    input              idelay_clk  , //200Mhz时钟，IDELAY时钟
    
    //以太网RGMII接口
    input              rgmii_rxc   , //RGMII接收时钟
    input              rgmii_rx_ctl, //RGMII接收数据控制信号
    input       [3:0]  rgmii_rxd   , //RGMII接收数据    

    //以太网GMII接口
    output             gmii_rx_clk , //GMII接收时钟
    output             gmii_rx_dv  , //GMII接收数据有效信号
    output      [7:0]  gmii_rxd      //GMII接收数据   
    );

//wire define
wire         rgmii_rxc_bufg;     //全局时钟缓存
wire         rgmii_rxc_bufio;    //全局时钟IO缓存
wire  [3:0]  rgmii_rxd_delay;    //rgmii_rxd输入延时
wire         rgmii_rx_ctl_delay; //rgmii_rx_ctl输入延时
wire  [1:0]  gmii_rxdv_t;        //两位GMII接收有效信号 

//*****************************************************
//**                    main code
//*****************************************************

assign gmii_rx_clk = rgmii_rxc_bufg;
assign gmii_rx_dv = gmii_rxdv_t[0] & gmii_rxdv_t[1];

//全局时钟缓存
GTP_CLKBUFG BUFG_inst(
    .CLKOUT(rgmii_rxc_bufg),// OUTPUT  
    .CLKIN(rgmii_rxc)  // INPUT  
);

//全局时钟IO缓存

GTP_IOCLKBUF #(
    .GATE_EN("FALSE") 
) u_GTP_IOCLKBUF (
    .CLKOUT(rgmii_rxc_bufio),// OUTPUT  
    .CLKIN(rgmii_rxc), // INPUT  
    .DI(1'b1)     // INPUT  
);

////输入双沿采样寄存器
GTP_IDDR_E1 #(
    .GRS_EN("TRUE"),
    .IDDR_MODE("SAME_PIPELINED"),
    .RS_TYPE(" SYNC_RESET") 
) u_iddr_rx_ctl (
    .Q0(gmii_rxdv_t[0]), // OUTPUT  
    .Q1(gmii_rxdv_t[1]), // OUTPUT  
    .CE(1'b1), // INPUT  
    .CLK(rgmii_rxc_bufio),// INPUT  
    .D(rgmii_rx_ctl),  // INPUT  
    .RS(1'b0)  // INPUT  
);

//rgmii_rxd输入延时与双沿采样
genvar i;
generate for (i=0; i<4; i=i+1) 
    begin : rxdata_bus	
GTP_IDDR_E1 #(
    .GRS_EN("TRUE"),
    .IDDR_MODE("SAME_PIPELINED"),
    .RS_TYPE(" SYNC_RESET") 
) u_iddr_rxd (
    .Q0(gmii_rxd[i]), // OUTPUT  
    .Q1(gmii_rxd[4+i]), // OUTPUT  
    .CE(1'b1), // INPUT  
    .CLK(rgmii_rxc_bufio),// INPUT  
    .D(rgmii_rxd[i]),  // INPUT  
    .RS(1'b0)  // INPUT  
);		
		
    end
endgenerate

endmodule