

//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename:ipm2l_spram.v
//////////////////////////////////////////////////////////////////////////////
module ipm2l_spram_v1_8_rom_test #(
    parameter  c_CAS_MODE       = "18K"         ,  // "18K", "36K", "64K"
    parameter  c_ADDR_WIDTH     = 10            ,
    parameter  c_DATA_WIDTH     = 32            ,
    parameter  c_OUTPUT_REG     = 0             ,
    parameter  c_RD_OCE_EN      = 0             ,
    parameter  c_FAB_REG        = 0             ,
    parameter  c_CLK_EN         = 0             ,
    parameter  c_ADDR_STROBE_EN = 0             ,
    parameter  c_RESET_TYPE     = "ASYNC"       ,
    parameter  c_POWER_OPT      = 0             ,
    parameter  c_CLK_OR_POL_INV = 0             ,
    parameter  c_INIT_FILE      = "NONE"        ,
    parameter  c_INIT_FORMAT    = "BIN"         ,
    parameter  c_WR_BYTE_EN     = 0             ,
    parameter  c_BE_WIDTH       = 8             ,
    parameter  c_RAM_MODE       = "SINGLE_PORT" ,
    parameter  c_WRITE_MODE     = "NORMAL_WRITE"
) (
    input  wire [c_ADDR_WIDTH-1 : 0]  addr        ,
    input  wire [c_DATA_WIDTH-1 : 0]  wr_data     ,
    output wire [c_DATA_WIDTH-1 : 0]  rd_data     ,
    input  wire                       wr_en       ,
    input  wire                       clk         ,
    input  wire                       clk_en      ,
    input  wire                       addr_strobe ,
    input  wire                       rst         ,
    input  wire [c_BE_WIDTH-1 : 0]    wr_byte_en  ,
    input  wire                       rd_oce
);

localparam INIT_EN = 1 ; // @IPC bool
localparam RST_VAL_EN = 0 ; // @IPC bool
`include "rom_test_init_param.v"

    localparam  c_WR_BYTE_WIDTH = c_WR_BYTE_EN ? (c_DATA_WIDTH/(c_BE_WIDTH==0 ? 1 : c_BE_WIDTH)) : ( (c_DATA_WIDTH%9 ==0) ? 9 : (c_DATA_WIDTH%8 ==0) ? 8 : 9 );
    localparam  N_DATA_WIDTH = c_ADDR_WIDTH <= 9  ? ( (c_DATA_WIDTH%9 == 0) ? ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 36 : 72 )
                                                    : (c_DATA_WIDTH%8 == 0) ? ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 32 : 64 ) :
                                                                              ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 36 : 72 ) ) :
                               c_ADDR_WIDTH == 10 ? ( (c_DATA_WIDTH%9 == 0) ? 36 :
                                                      (c_DATA_WIDTH%8 == 0) ? 32 :
                                                                              36 ) :
                               c_ADDR_WIDTH == 11 ? ( (c_DATA_WIDTH%9 == 0) ? 18 :
                                                      (c_DATA_WIDTH%8 == 0) ? 16 :
                                                                              18 ) :
                               c_ADDR_WIDTH == 12 ? ( (c_DATA_WIDTH%9 == 0) ? 9  :
                                                      (c_DATA_WIDTH%8 == 0) ? 8  :
                                                                              9  ) :
                               c_ADDR_WIDTH == 13 ? 4 :
                               c_ADDR_WIDTH == 14 ? 2 :
                                                    1 ;

    localparam  L_DATA_WIDTH = c_DATA_WIDTH == 1    ? 1  :
                               c_DATA_WIDTH == 2    ? 2  :
                               c_DATA_WIDTH <= 4    ? 4  :
                               c_DATA_WIDTH <= 9    ? ( (c_DATA_WIDTH%9 == 0) ? 9  : (c_DATA_WIDTH%8) == 0 ? 8  : 9  ) :
                               c_DATA_WIDTH <= 18   ? ( (c_DATA_WIDTH%9 == 0) ? 18 : (c_DATA_WIDTH%8) == 0 ? 16 : 18 ) :
                               c_DATA_WIDTH <= 36   ? ( (c_DATA_WIDTH%9 == 0) ? 36 : (c_DATA_WIDTH%8) == 0 ? 32 : 36 ) :
                                                      ( (c_DATA_WIDTH%9 == 0) ? ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 36 : 72 ) :
                                                        (c_DATA_WIDTH%8 == 0) ? ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 32 : 64 ) :
                                                                                ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 36 : 72 ) ) ;

    //********************************************************************************************************************************************************************
    localparam  N_BYTE_DATA_WIDTH = (c_WR_BYTE_WIDTH == 8) ? ( (c_ADDR_WIDTH <= 9  ) ? ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 32 : 64 ) :
                                                               (c_ADDR_WIDTH == 10 ) ? 32 :
                                                                                       16 ) :
                                                             ( (c_ADDR_WIDTH <= 9  ) ? ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 36 : 72 ) :
                                                               (c_ADDR_WIDTH <= 10 ) ? 36 :
                                                                                       18 );

    localparam  L_BYTE_DATA_WIDTH = (c_WR_BYTE_WIDTH == 8) ? ( (c_DATA_WIDTH <= 16) ? 16 :
                                                               (c_DATA_WIDTH <= 32) ? 32 :
                                                                                         ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 32 : 64 ) ) :
                                                             ( (c_DATA_WIDTH <= 18) ? 18 :
                                                               (c_DATA_WIDTH <= 36) ? 36 :
                                                                                         ( ((c_ADDR_STROBE_EN == 1) || (c_WRITE_MODE != "NORMAL_WRITE")) ? 36 : 72 ) );

    //DRM_DATA_WIDTH is the  port parameter  of DRM
    localparam  DRM_DATA_WIDTH  = (c_POWER_OPT == 1) ? (c_WR_BYTE_EN ==1 ? L_BYTE_DATA_WIDTH : L_DATA_WIDTH):
                                                       (c_WR_BYTE_EN ==1 ? N_BYTE_DATA_WIDTH : N_DATA_WIDTH);

    localparam  DATA_LOOP_NUM  = (c_DATA_WIDTH%DRM_DATA_WIDTH == 0) ? (c_DATA_WIDTH/DRM_DATA_WIDTH):(c_DATA_WIDTH/DRM_DATA_WIDTH + 1);

    localparam  Q_DATA_WIDTH    = (DRM_DATA_WIDTH == 72) ? 36 : (DRM_DATA_WIDTH == 64) ? 32 : DRM_DATA_WIDTH;
//    localparam  Q_DATA_WIDTH_H  = (DRM_DATA_WIDTH == 72) ? 18 : (DRM_DATA_WIDTH == 64) ? 16 : Q_DATA_WIDTH;
    //DRM_ADDR_WIDTH is the ADDR_WIDTH of INSTANCE DRM primitives
    localparam  DRM_ADDR_WIDTH = DRM_DATA_WIDTH == 1  ? 15:
                                 DRM_DATA_WIDTH == 2  ? 14:
                                 DRM_DATA_WIDTH == 4  ? 13:
                                 DRM_DATA_WIDTH == 8  ? 12:
                                 DRM_DATA_WIDTH == 9  ? 12:
                                 DRM_DATA_WIDTH == 16 ? 11:
                                 DRM_DATA_WIDTH == 18 ? 11:
                                 DRM_DATA_WIDTH == 32 ? 10:
                                 DRM_DATA_WIDTH == 36 ? 10:
                                                         9;

    localparam  ADDR_WIDTH  = c_ADDR_WIDTH > DRM_ADDR_WIDTH ? c_ADDR_WIDTH : DRM_ADDR_WIDTH;
    //CS_ADDR_WIDTH is the CS address width to choose the DRM18K CS_ADDR_WIDTH=  [ extra-addres + cs[2]+csp[1]+cs[0] ]
    localparam  CS_ADDR_WIDTH  = ADDR_WIDTH - DRM_ADDR_WIDTH;

    //ADDR_LOOP_NUM difine how many loops to cascade the c_ADDR_WIDTH
    localparam  ADDR_LOOP_NUM  = 2**CS_ADDR_WIDTH;
    //CAS_DATA_WIDTH is the cascaded  data width
    localparam  CAS_DATA_WIDTH   =  DRM_DATA_WIDTH*DATA_LOOP_NUM;
    localparam  Q_CAS_DATA_WIDTH =  Q_DATA_WIDTH*DATA_LOOP_NUM;

    localparam  WR_BYTE_WIDTH    =  c_WR_BYTE_EN == 1 ? c_WR_BYTE_WIDTH : ( (DRM_DATA_WIDTH >=8 || DRM_DATA_WIDTH >=9 ) ? ((c_DATA_WIDTH%9 == 0) ? 9 : (c_DATA_WIDTH%8 == 0) ? 8 : 9 ) : 1 );

    //MASK_NUM the mask base value
    localparam  MASK_NUM  = ( DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64 ) ? (ADDR_LOOP_NUM > 4 ? 2 : 4 ):
                            ( ADDR_LOOP_NUM >8 ) ? (( DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64 ) ? 2 : 4) : 8;

    //parameter  check
    initial begin
       if(c_ADDR_WIDTH>20 || c_ADDR_WIDTH<9 ) begin
          $display("IPSpecCheck: 04030219 ipm2l_flex_spram parameter setting error !!!: c_ADDR_WIDTH must between 9-20 when DRM Resource is 36K")/* PANGO PAP_WARNING */;
//          $finish;
       end
       else if( c_DATA_WIDTH>1152 || c_DATA_WIDTH<1 ) begin
          $display("IPSpecCheck: 04030220 ipm2l_flex_spram parameter setting error !!!: c_DATA_WIDTH must between 1-1152")/* PANGO PAP_WARNING */;
//          $finish;
       end
//       else if( (2**c_ADDR_WIDTH) * c_DATA_WIDTH>1152*1024 ) begin
//          $display("IPSpecCheck: 04030221 ipm2l_flex_spram parameter setting error !!!: ipml_flex_ram must less than  1152k")/* PANGO PAP_ERROR */;
//          $finish;
//       end
       else if(c_OUTPUT_REG!=1 && c_OUTPUT_REG!=0 ) begin
          $display("IPSpecCheck: 04030222 ipm2l_flex_spram parameter setting error !!!: c_OUTPUT_REG must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if ( c_FAB_REG!=1 && c_FAB_REG!=0  ) begin
           $display("IPSpecCheck: 04030253 ipm2l_flex_spram parameter setting error !!!: c_FAB_REGmust be 0 or 1")/* PANGO PAP_ERROR */;
           $finish;
       end
       else if ( c_RD_OCE_EN!=0 && c_RD_OCE_EN!=1 ) begin
          $display("IPSpecCheck: 04030223 ipm2l_flex_spram parameter setting error !!!: c_RD_OCE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if ( c_CLK_OR_POL_INV!=0 && c_CLK_OR_POL_INV!=1 ) begin
          $display("IPSpecCheck: 04030224 ipm2l_flex_spram parameter setting error !!!: c_CLK_OR_POL_INV must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if( c_RD_OCE_EN==1 && (c_OUTPUT_REG==0 && c_FAB_REG==0) ) begin
           $display("IPSpecCheck: 04030225 ipm2l_flex_spram parameter setting error !!!: c_OUTPUT_REG and c_FAB_REG could not be 0 at same time when c_RD_OCE_EN is 1")/* PANGO PAP_ERROR */;
           $finish;
       end
       else if( c_CLK_OR_POL_INV==1 && (c_OUTPUT_REG==0 && c_FAB_REG==0) ) begin
           $display("IPSpecCheck: 04030226 ipm2l_flex_spram parameter setting error !!!: c_OUTPUT_REG and c_FAB_REG could not be 0 at same time when c_CLK_OR_POL_INV is 1")/* PANGO PAP_ERROR */;
           $finish;
       end
       else if ( c_CLK_EN!=0 && c_CLK_EN!=1 ) begin
          $display("IPSpecCheck: 04030227 ipm2l_flex_spram parameter setting error !!!: c_CLK_EN must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if ( c_ADDR_STROBE_EN!=0 && c_ADDR_STROBE_EN!=1 ) begin
          $display("IPSpecCheck: 04030228 ipm2l_flex_spram parameter setting error !!!: c_ADDR_STROBE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_RESET_TYPE!="ASYNC" && c_RESET_TYPE!="SYNC") begin
          $display("IPSpecCheck: 04030029 ipm2l_flex_spram parameter setting error !!!: c_RESET_TYPE must be ASYNC or SYNC")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_POWER_OPT!=1 && c_POWER_OPT!=0 ) begin
          $display("IPSpecCheck: 04030230 ipm2l_flex_spram parameter setting error !!!: c_POWER_OPT must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_INIT_FORMAT!="BIN" && c_INIT_FORMAT!="HEX" ) begin
          $display("IPSpecCheck: 04030231 ipm2l_flex_spram parameter setting error !!!: c_INIT_FORMAT must be bin or hex ")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_WR_BYTE_EN!=0 && c_WR_BYTE_EN!=1 ) begin
          $display("IPSpecCheck: 04030232 ipm2l_flex_spram parameter setting error !!!: c_WR_BYTE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_WR_BYTE_EN==1) begin
          if(c_WR_BYTE_WIDTH!=8 &&  c_WR_BYTE_WIDTH!=9 ) begin
             $display("IPSpecCheck: 04030233 ipm2l_flex_spram parameter setting error !!!: c_WR_BYTE_WIDTH must be 8 or 9")/* PANGO PAP_ERROR */;
             $finish;
          end
          if( (c_DATA_WIDTH%8)!=0 && (c_DATA_WIDTH%9)!=0 ) begin
             $display("IPSpecCheck: 04030234 ipm2l_flex_spram parameter setting error !!!: c_DATA_WIDTH must be 8*N or 9*N")/* PANGO PAP_ERROR */;
             $finish;
          end
       end
       else if(c_WRITE_MODE!="NORMAL_WRITE" && c_WRITE_MODE!="TRANSPARENT_WRITE" && c_WRITE_MODE!="READ_BEFORE_WRITE") begin
             $display("IPSpecCheck: 04030235 ipm2l_flex_spram parameter setting error !!!: c_WRITE_MODE must be NORMAL_WRITE or TRANSPARENT_WRITE or READ_BEFORE_WRITE")/* PANGO PAP_ERROR */;
             $finish;
       end
       else if ( c_ADDR_STROBE_EN == 1 && DRM_DATA_WIDTH > 36) begin
           $display("IPSpecCheck: 04030236 ipm2l_flex_spram parameter setting error !!!: c_ADDR_STROBE_EN does not work when DRM36K mode is 512x72|64")/* PANGO PAP_ERROR */;
           $finish;
       end
    end
    //main code
    //********************************************************************************************************************************************************
    //inner variables

    wire [CAS_DATA_WIDTH-1:0]                  wr_data_bus   ;
    reg  [Q_CAS_DATA_WIDTH-1:0]                da_data_bus   ;        //the data bus of data_cascaded instance DRM
    wire [Q_CAS_DATA_WIDTH*ADDR_LOOP_NUM-1:0]  qa_data_bus   ;        //the total data width of instance DRM
    wire [ADDR_WIDTH-1:0]                      addr_bus      ;
    reg  [DATA_LOOP_NUM*16-1:0]                drm_addr      ;        //write address to all instance DRM
    reg                                        cs_bit0       ;        //write cs[0]  to all instance DRM
    reg  [ADDR_LOOP_NUM-1:0]                   cs_bit1_bus   ;        //write cs[1]  to all instance DRM
    reg  [ADDR_LOOP_NUM-1:0]                   cs_bit2_bus   ;        //write cs[2] bus  to every data_cascaded DRM-block

    wire                                       wr_en_b       ;
    wire                                       clk_en_b      ;
    wire [CAS_DATA_WIDTH*ADDR_LOOP_NUM-1:0]    rd_data_bus   ;
    reg  [Q_CAS_DATA_WIDTH-1:0]                db_data_bus   ;        //the data bus of data_cascaded instance DRM
    wire [Q_CAS_DATA_WIDTH*ADDR_LOOP_NUM-1:0]  qb_data_bus   ;        //the total data width of instance DRM
    reg  [DATA_LOOP_NUM*16-1:0]                drm_b_addr    ;
    reg                                        csb_bit0      ;        //write cs[0]  to all instance DRM
    reg  [ADDR_LOOP_NUM-1:0]                   csb_bit1_bus  ;        //write cs[1]  to all instance DRM
    reg  [ADDR_LOOP_NUM-1:0]                   csb_bit2_bus  ;        //write cs[2] bus  to every data_cascaded DRM-block

    //byte enable
    wire [8*DATA_LOOP_NUM-1 : 0]   wr_byte_en_bus;
    wire [8*DATA_LOOP_NUM-1 : 0]   wr_byte_en_bus_m;
    wire [4*DATA_LOOP_NUM-1 : 0]   wr_byte_en_bus_b;
    //********************************************************************************************************************************************************
    //write data mux
    assign  wr_data_bus[CAS_DATA_WIDTH-1:0] = {{(CAS_DATA_WIDTH-c_DATA_WIDTH){1'b0}},wr_data[c_DATA_WIDTH-1:0]};

    assign  addr_bus[ADDR_WIDTH-1:0] = {{(ADDR_WIDTH-c_ADDR_WIDTH){1'b0}},addr[c_ADDR_WIDTH-1:0]};
      //drive wr_byte_en_bus
    assign wr_byte_en_bus = (c_WR_BYTE_EN == 0) ? {{8*DATA_LOOP_NUM}{1'b1}} : {{(8*DATA_LOOP_NUM-c_BE_WIDTH){1'b0}},wr_byte_en[c_BE_WIDTH-1:0]};

    //generate drm_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
    integer gen_wa;
    generate
    always@(*) begin
       for(gen_wa=0;gen_wa < DATA_LOOP_NUM;gen_wa = gen_wa +1 ) begin
          case(DRM_DATA_WIDTH)
             1     : begin
                         drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0]};
                         drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0]};
                     end
             2     : begin
                         drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],1'b0};
                         drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],1'b0};
                     end
             4     : begin
                         drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],2'b00};
                         drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],2'b00};
                     end
             8,9   : begin
                         drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],3'b000};
                         drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],3'b000};
                     end
             16,18 : begin
                         drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],4'b0000};
                         drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],4'b0000};
                     end
             32,36 : begin
                         drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],5'b0_0000};
                         drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],5'b0_0000};
                     end
             64,72 : begin // ONLY WORK FOR NORMAL WRITE MODE
//                         if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE"))
//                         begin
//                             drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],6'b00_0000};
//                             drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],6'b10_0000};
//                         end
//                         else
//                         begin
                             drm_addr[gen_wa*16 +: 16]   = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],6'b00_0000};
                             drm_b_addr[gen_wa*16 +: 16] = {1'b1,addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0],6'b00_0000};
//                         end
                     end
             default: begin
                          drm_addr[gen_wa*16 +: 16]   = 16'b0;
                          drm_b_addr[gen_wa*16 +: 16] = 16'b0;
                      end
          endcase
       end
    end
    endgenerate

    localparam  CS_ADDR_3_LSB = (CS_ADDR_WIDTH >= 3) ? (ADDR_WIDTH-CS_ADDR_WIDTH+1) : (ADDR_WIDTH-2);  //avoid reveral index of wr_addr_bus
    localparam  CS_ADDR_4_LSB = (CS_ADDR_WIDTH >= 4) ? (ADDR_WIDTH-1-CS_ADDR_WIDTH+3) : (ADDR_WIDTH-2); //avoid reveral index of wr_addr_bus

    //generate  CS control signal
    integer gen_m;
    generate
    always@(*) begin
       for(gen_m=0;gen_m<ADDR_LOOP_NUM;gen_m=gen_m+1) begin
          if(DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64) begin
             if(CS_ADDR_WIDTH == 0) begin
                cs_bit0 = 0;
                cs_bit1_bus[gen_m] = 0;
//                if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE"))
//                    cs_bit2_bus[gen_m] = 1'b1;
//                else
                cs_bit2_bus[gen_m] = 1'b0;
             end
             else if(CS_ADDR_WIDTH == 1) begin
                cs_bit0 = addr_bus[ADDR_WIDTH-CS_ADDR_WIDTH];
                cs_bit1_bus[gen_m] = 0;
//                if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE"))
//                    cs_bit2_bus[gen_m] = 1'b1;
//                else
                cs_bit2_bus[gen_m] = 1'b0;
             end
             else if(CS_ADDR_WIDTH == 2) begin
                cs_bit0 = addr_bus[ADDR_WIDTH-CS_ADDR_WIDTH];
                cs_bit1_bus[gen_m] = addr_bus[ADDR_WIDTH-1];
//                if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE"))
//                    cs_bit2_bus[gen_m] = 1'b1;
//                else
                cs_bit2_bus[gen_m] = 1'b0;
             end
             else if(CS_ADDR_WIDTH >= 3) begin
                cs_bit0 = addr_bus[ADDR_WIDTH-CS_ADDR_WIDTH];
                cs_bit1_bus[gen_m] = (addr_bus[(ADDR_WIDTH-1):CS_ADDR_3_LSB] == (gen_m/2)) ? 0:1;
//                if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE"))
//                    cs_bit2_bus[gen_m] = 1'b1;
//                else
                cs_bit2_bus[gen_m] = 1'b0;
             end
          end
          else begin
             if(CS_ADDR_WIDTH == 0) begin
                cs_bit0 = 0;
                cs_bit1_bus[gen_m] = 0;
                cs_bit2_bus[gen_m] = 0;
             end
             else if(CS_ADDR_WIDTH == 1) begin
                cs_bit0 = addr_bus[ADDR_WIDTH-CS_ADDR_WIDTH];
                cs_bit1_bus[gen_m] = 0;
                cs_bit2_bus[gen_m] = 0;
             end
             else if(CS_ADDR_WIDTH == 2) begin
                cs_bit0 = addr_bus[ADDR_WIDTH-2];
                cs_bit1_bus[gen_m] = addr_bus[ADDR_WIDTH-1];
                cs_bit2_bus[gen_m] = 0;
             end
             else if(CS_ADDR_WIDTH == 3) begin
                cs_bit0 = addr_bus[ADDR_WIDTH-3];
                cs_bit1_bus[gen_m] = addr_bus[ADDR_WIDTH-2];
                cs_bit2_bus[gen_m] = addr_bus[ADDR_WIDTH-1];
             end
             else if(CS_ADDR_WIDTH >= 4) begin
                cs_bit0 = addr_bus[ADDR_WIDTH-CS_ADDR_WIDTH];
                cs_bit1_bus[gen_m] = addr_bus[ADDR_WIDTH-CS_ADDR_WIDTH+1];
                cs_bit2_bus[gen_m] = (addr_bus[(ADDR_WIDTH-1):CS_ADDR_4_LSB] == (gen_m/4)) ? 0 : 1;
             end
          end
       end
    end
    endgenerate

    //B port CS
    always@(*) begin
       if(DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64)
          csb_bit0 = cs_bit0 ;
       else
          csb_bit0 = 0;
    end

    always@(*) begin
       if(DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64)
          csb_bit1_bus = cs_bit1_bus ;
       else
          csb_bit1_bus = 'b0;
    end

    always@(*) begin
       if(DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64) //begin
//          if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE"))
//              csb_bit2_bus = cs_bit2_bus;
//          else
          csb_bit2_bus = cs_bit2_bus & (~wr_en) ;
//       end
       else
          csb_bit2_bus = 'b0;
    end

    wire [36*DATA_LOOP_NUM*ADDR_LOOP_NUM-1:0]  QA_bus;
    wire [36*DATA_LOOP_NUM*ADDR_LOOP_NUM-1:0]  QB_bus;
    wire [36*DATA_LOOP_NUM-1:0]                DA_bus;
    wire [36*DATA_LOOP_NUM-1:0]                DB_bus;

    integer  drm_d_i;
    generate
    always@(*) begin
       for (drm_d_i = 0; drm_d_i <DATA_LOOP_NUM; drm_d_i = drm_d_i+1) begin
          db_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH] = 'b0;
          da_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH] = 'b0;
          if(DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64)
//             if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE")) begin
                {db_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH], da_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH]} = wr_data_bus[drm_d_i*DRM_DATA_WIDTH +:DRM_DATA_WIDTH];
//             end
//             else begin
//                {db_data_bus[drm_d_i*Q_DATA_WIDTH+Q_DATA_WIDTH_H +:Q_DATA_WIDTH_H], da_data_bus[drm_d_i*Q_DATA_WIDTH+Q_DATA_WIDTH_H +:Q_DATA_WIDTH_H],
//                 db_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH_H], da_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH_H]} = wr_data_bus[drm_d_i*DRM_DATA_WIDTH +:DRM_DATA_WIDTH];
//             end
          else begin
             da_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH] = wr_data_bus[drm_d_i*DRM_DATA_WIDTH +:DRM_DATA_WIDTH];
             db_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH] = 'b0;
          end
       end
    end
    endgenerate

    localparam RAM_MODE_SEL       = (c_RAM_MODE == "ROM") ? "ROM"
                                                          : ((DRM_DATA_WIDTH > 18) && (c_WRITE_MODE != "NORMAL_WRITE")) ? "TRUE_DUAL_PORT"   : "SINGLE_PORT";
//    localparam DRM_DATA_WIDTH_SEL = (c_RAM_MODE == "ROM") ? DRM_DATA_WIDTH
//                                                          : ((DRM_DATA_WIDTH > 18) && (c_WRITE_MODE != "NORMAL_WRITE")) ? (DRM_DATA_WIDTH/2) : DRM_DATA_WIDTH;

    //generate constructs: ADDR_LOOP to cascade request address  and  DATA LOOP to cascade request data
    genvar gen_i,gen_j;
    generate
    for(gen_j=0;gen_j<ADDR_LOOP_NUM;gen_j=gen_j+1) begin:ADDR_LOOP
        for(gen_i=0;gen_i<DATA_LOOP_NUM;gen_i=gen_i+1) begin:DATA_LOOP
            localparam [2:0] CSA_MASK     = ( DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64 ) ? (gen_j%MASK_NUM & 3'b011) : (gen_j%MASK_NUM);
            localparam [2:0] CSB_MASK     = ( DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64 ) ? (gen_j%MASK_NUM & 3'b011) : (gen_j%MASK_NUM);
//            localparam [2:0] CSA_MASK_SEL = ((DRM_DATA_WIDTH > 18) && (c_WRITE_MODE != "NORMAL_WRITE")) ? (3'b100 | gen_j%MASK_NUM) : CSA_MASK;
//            localparam [2:0] CSB_MASK_SEL = ((DRM_DATA_WIDTH > 18) && (c_WRITE_MODE != "NORMAL_WRITE")) ? (3'b100 | gen_j%MASK_NUM) : CSB_MASK;

        //write data
            if( Q_DATA_WIDTH == 32 ) begin
               assign  qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = {QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+27) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+18) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DA_bus[(gen_i*36+27) +:8 ],DA_bus[(gen_i*36+18) +:8],DA_bus[(gen_i*36+9) +:8 ],DA_bus[gen_i*36 +:8]} = da_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];
            end
            else if( Q_DATA_WIDTH == 16 ) begin
               assign  qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = {QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DA_bus[(gen_i*36+9) +:8 ],DA_bus[gen_i*36 +:8]} = da_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];
            end
            else begin
               assign  qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:Q_DATA_WIDTH];
               assign  DA_bus[gen_i*36 +:Q_DATA_WIDTH] = da_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];
            end

            if( Q_DATA_WIDTH == 32 ) begin
               assign  qb_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = {QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+27) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+18) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DB_bus[(gen_i*36+27) +:8],DB_bus[(gen_i*36+18) +:8],DB_bus[(gen_i*36+9) +:8],DB_bus[gen_i*36 +:8]} = db_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];
            end
            else if( Q_DATA_WIDTH == 16 ) begin
               assign  qb_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = {QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DB_bus[(gen_i*36+9) +:8],DB_bus[gen_i*36 +:8]} = db_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];
            end
            else begin
               assign  qb_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:Q_DATA_WIDTH];
               assign  DB_bus[gen_i*36 +:Q_DATA_WIDTH] = db_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];
            end

            assign wr_en_b  = (DRM_DATA_WIDTH <= 36) ? 1'b0 : (c_WRITE_MODE == "NORMAL_WRITE") ? 1'b0 : wr_en;
            assign clk_en_b = (DRM_DATA_WIDTH <= 36) ? 1'b0 : (c_WRITE_MODE == "NORMAL_WRITE") ? ~wr_en & clk_en : clk_en;

            case(DRM_DATA_WIDTH)
                1:      begin
                            assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  wr_byte_en_bus[gen_i*8 +: 8];
                            assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
                        end
                2:      begin
                            assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  wr_byte_en_bus[gen_i*8 +: 8];
                            assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
                        end
                4:      begin
                            assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  wr_byte_en_bus[gen_i*8 +: 8];
                            assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
                        end
                8,9:    begin
                            assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  wr_byte_en_bus[gen_i*8 +: 8];
                            assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
                        end
                16,18:  begin
                            assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  (c_WR_BYTE_EN == 1) ? {6'b00_0000, wr_byte_en_bus[gen_i*2 +:2]} : wr_byte_en_bus[gen_i*8 +: 8];
                            assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
                        end
                32,36:  begin
                            assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  (c_WR_BYTE_EN == 1) ? {4'b0000,wr_byte_en_bus[gen_i*4 +:4]} : wr_byte_en_bus[gen_i*8 +: 8];
                            assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
                        end
                64,72:  begin
//                            if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE")) begin
//                                assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  (c_WR_BYTE_EN == 1) ? {4'b0000, wr_byte_en_bus[gen_i*8 +:4]} : wr_byte_en_bus[gen_i*8 +: 8];
//                                assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  (c_WR_BYTE_EN == 1) ? wr_byte_en_bus[gen_i*8+4 +:4]          : 4'b1111;
//                            end
//                            else begin
                                assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  (c_WR_BYTE_EN == 1) ?  wr_byte_en_bus[gen_i*8 +: 8] : wr_byte_en_bus[gen_i*8 +: 8];
                                assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
//                            end
                        end
                default: begin
                             assign wr_byte_en_bus_m[gen_i*8 +: 8]  =  8'b00000000;
                             assign wr_byte_en_bus_b[gen_i*4 +: 4]  =  4'b0000;
                         end
            endcase

            GTP_DRM36K_E1 # (

                .INIT_00                  (INIT_00[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_01                  (INIT_01[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_02                  (INIT_02[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_03                  (INIT_03[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_04                  (INIT_04[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_05                  (INIT_05[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_06                  (INIT_06[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_07                  (INIT_07[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_08                  (INIT_08[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_09                  (INIT_09[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0A                  (INIT_0A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0B                  (INIT_0B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0C                  (INIT_0C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0D                  (INIT_0D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0E                  (INIT_0E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0F                  (INIT_0F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_10                  (INIT_10[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_11                  (INIT_11[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_12                  (INIT_12[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_13                  (INIT_13[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_14                  (INIT_14[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_15                  (INIT_15[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_16                  (INIT_16[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_17                  (INIT_17[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_18                  (INIT_18[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_19                  (INIT_19[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1A                  (INIT_1A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1B                  (INIT_1B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1C                  (INIT_1C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1D                  (INIT_1D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1E                  (INIT_1E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1F                  (INIT_1F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_20                  (INIT_20[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_21                  (INIT_21[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_22                  (INIT_22[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_23                  (INIT_23[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_24                  (INIT_24[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_25                  (INIT_25[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_26                  (INIT_26[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_27                  (INIT_27[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_28                  (INIT_28[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_29                  (INIT_29[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2A                  (INIT_2A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2B                  (INIT_2B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2C                  (INIT_2C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2D                  (INIT_2D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2E                  (INIT_2E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2F                  (INIT_2F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_30                  (INIT_30[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_31                  (INIT_31[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_32                  (INIT_32[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_33                  (INIT_33[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_34                  (INIT_34[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_35                  (INIT_35[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_36                  (INIT_36[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_37                  (INIT_37[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_38                  (INIT_38[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_39                  (INIT_39[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3A                  (INIT_3A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3B                  (INIT_3B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3C                  (INIT_3C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3D                  (INIT_3D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3E                  (INIT_3E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3F                  (INIT_3F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_40                  (INIT_40[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_41                  (INIT_41[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_42                  (INIT_42[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_43                  (INIT_43[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_44                  (INIT_44[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_45                  (INIT_45[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_46                  (INIT_46[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_47                  (INIT_47[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_48                  (INIT_48[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_49                  (INIT_49[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4A                  (INIT_4A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4B                  (INIT_4B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4C                  (INIT_4C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4D                  (INIT_4D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4E                  (INIT_4E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4F                  (INIT_4F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_50                  (INIT_50[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_51                  (INIT_51[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_52                  (INIT_52[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_53                  (INIT_53[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_54                  (INIT_54[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_55                  (INIT_55[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_56                  (INIT_56[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_57                  (INIT_57[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_58                  (INIT_58[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_59                  (INIT_59[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5A                  (INIT_5A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5B                  (INIT_5B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5C                  (INIT_5C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5D                  (INIT_5D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5E                  (INIT_5E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5F                  (INIT_5F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_60                  (INIT_60[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_61                  (INIT_61[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_62                  (INIT_62[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_63                  (INIT_63[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_64                  (INIT_64[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_65                  (INIT_65[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_66                  (INIT_66[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_67                  (INIT_67[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_68                  (INIT_68[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_69                  (INIT_69[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6A                  (INIT_6A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6B                  (INIT_6B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6C                  (INIT_6C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6D                  (INIT_6D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6E                  (INIT_6E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6F                  (INIT_6F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_70                  (INIT_70[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_71                  (INIT_71[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_72                  (INIT_72[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_73                  (INIT_73[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_74                  (INIT_74[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_75                  (INIT_75[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_76                  (INIT_76[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_77                  (INIT_77[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_78                  (INIT_78[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_79                  (INIT_79[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7A                  (INIT_7A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7B                  (INIT_7B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7C                  (INIT_7C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7D                  (INIT_7D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7E                  (INIT_7E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7F                  (INIT_7F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),

                .GRS_EN                   ( "FALSE"                  ),
                .CSA_MASK                 ( CSA_MASK                 ),
                .CSB_MASK                 ( CSB_MASK                 ),
                .DATA_WIDTH_A             ( DRM_DATA_WIDTH           ),
                .DATA_WIDTH_B             ( DRM_DATA_WIDTH           ),
                .WRITE_MODE_A             ( c_WRITE_MODE             ),
                .WRITE_MODE_B             ( c_WRITE_MODE             ),
                .DOA_REG                  ( c_OUTPUT_REG             ),
                .DOB_REG                  ( c_OUTPUT_REG             ),
                .DOA_REG_CLKINV           ( c_CLK_OR_POL_INV         ),
                .DOB_REG_CLKINV           ( c_CLK_OR_POL_INV         ),

                .RST_TYPE                 ( c_RESET_TYPE             ),
                .RAM_MODE                 ( RAM_MODE_SEL             ),
                .INIT_FILE                ( c_INIT_FILE              ),
                .RAM_CASCADE              ( "NONE"                   ),
                .ECC_WRITE_EN             ( "FALSE"                  ),
                .ECC_READ_EN              ( "FALSE"                  ),
                .BLOCK_X                  ( gen_i                    ),
                .BLOCK_Y                  ( gen_j                    ),
                .RAM_ADDR_WIDTH           ( ADDR_WIDTH               ),
                .RAM_DATA_WIDTH           ( CAS_DATA_WIDTH           ),
                .INIT_FORMAT              ( c_INIT_FORMAT            )
            ) U_GTP_DRM36K_E1 (
                .DOA                      ( QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:36]  ),
                .ADDRA                    ( drm_addr[gen_i*16 +:16]                         ),
                .ADDRA_HOLD               ( addr_strobe                                     ),
                .BWEA                     ( wr_byte_en_bus_m[gen_i*8 +:8]                   ),
                .DIA                      ( DA_bus[gen_i*36 +:36]                           ),
                .CSA                      ( {cs_bit2_bus[gen_j], cs_bit1_bus[gen_j], cs_bit0}      ),
                .WEA                      ( wr_en                                           ),
                .CLKA                     ( clk                                             ),
                .CEA                      ( clk_en                                          ),
                .ORCEA                    ( rd_oce                                          ),
                .RSTA                     ( rst                                             ),
                .CINA                     (                                                 ),
                .COUTA                    (                                                 ),

                .DOB                      ( QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:36]  ),
                .ADDRB                    ( drm_b_addr[15:0]                                ),
                .ADDRB_HOLD               ( addr_strobe                                     ),
                .BWEB                     ( wr_byte_en_bus_b[gen_i*4 +:4]                   ),
                .DIB                      ( DB_bus[gen_i*36 +:36]                           ),
                .CSB                      ( {csb_bit2_bus[gen_j],csb_bit1_bus[gen_j],csb_bit0}     ),
                .WEB                      ( wr_en_b                                         ),
                .CLKB                     ( clk                                             ),
                .CEB                      ( clk_en_b                                        ),
                .ORCEB                    ( rd_oce                                          ),
                .RSTB                     ( rst                                             ),
                .CINB                     (                                                 ),
                .COUTB                    (                                                 ),

                .INJECT_SBITERR           (                                                 ),
                .INJECT_DBITERR           (                                                 ),
                .ECC_SBITERR              (                                                 ),
                .ECC_DBITERR              (                                                 ),
                .ECC_RDADDR               (                                                 ),
                .ECC_PARITY               (                                                 )
            );


            if(DRM_DATA_WIDTH == 72 || DRM_DATA_WIDTH == 64) begin
//               if ((DRM_DATA_WIDTH > 36) && (c_WRITE_MODE != "NORMAL_WRITE"))
                  assign rd_data_bus[gen_i*DRM_DATA_WIDTH+gen_j*CAS_DATA_WIDTH +:DRM_DATA_WIDTH] = {qb_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] ,qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH]};
//               else
//                  assign rd_data_bus[gen_i*DRM_DATA_WIDTH+gen_j*CAS_DATA_WIDTH +:DRM_DATA_WIDTH] = {qb_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH+Q_DATA_WIDTH_H +:Q_DATA_WIDTH_H] ,qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH+Q_DATA_WIDTH_H +:Q_DATA_WIDTH_H],
//                                                                                                    qb_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH_H] ,qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH_H]};
            end
            else
                assign rd_data_bus[gen_i*DRM_DATA_WIDTH+gen_j*CAS_DATA_WIDTH +:DRM_DATA_WIDTH] = qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH];
        end
    end
    endgenerate

    //rd_data: extra mux combination  logic
    localparam   ADDR_SEL_LSB = (CS_ADDR_WIDTH > 0) ? (ADDR_WIDTH - CS_ADDR_WIDTH) : (ADDR_WIDTH - 1);

    wire [CS_ADDR_WIDTH-1:0]   addr_bus_rd_sel;
    reg  [CS_ADDR_WIDTH-1:0]   addr_bus_rd_ce;
    reg  [CS_ADDR_WIDTH-1:0]   addr_bus_rd_ce_ff;
    wire [CS_ADDR_WIDTH-1:0]   addr_bus_rd_ce_mux;
    reg  [CS_ADDR_WIDTH-1:0]   addr_bus_rd_oce;
    reg  [CS_ADDR_WIDTH-1:0]   addr_bus_rd_invt;
    reg  [CAS_DATA_WIDTH-1:0]  rd_full_data;

    reg     wr_en_ff;

    //CE
    always @(posedge clk)
    begin
        if (~addr_strobe & clk_en)
            addr_bus_rd_ce <= addr_bus[ADDR_WIDTH-1:ADDR_SEL_LSB];
    end

    always @(posedge clk)
    begin
        if (clk_en)
            wr_en_ff <= wr_en;
    end

    always @(posedge clk)
    begin
        if (~wr_en_ff)
            addr_bus_rd_ce_ff   <= addr_bus_rd_ce;
    end

    assign addr_bus_rd_ce_mux = (c_WRITE_MODE != "NORMAL_WRITE") ? addr_bus_rd_ce : wr_en_ff ? addr_bus_rd_ce_ff : addr_bus_rd_ce;

    //OCE
    always @(posedge clk)
    begin
        if (rd_oce)
            addr_bus_rd_oce <= addr_bus_rd_ce_mux;
    end

    //INVT
    always @(negedge clk)
    begin
        if (rd_oce)
            addr_bus_rd_invt <= addr_bus_rd_ce_mux;
    end

    assign  addr_bus_rd_sel = (c_CLK_OR_POL_INV == 1) ? addr_bus_rd_invt : (c_OUTPUT_REG == 1) ? addr_bus_rd_oce : addr_bus_rd_ce_mux;

    integer n;
    generate
    always@(*)
    begin
       rd_full_data = 0;
       if(ADDR_LOOP_NUM>1) begin
          for(n=0;n<ADDR_LOOP_NUM;n=n+1) begin
             if(addr_bus_rd_sel == n)
                rd_full_data = rd_data_bus[n*CAS_DATA_WIDTH +: CAS_DATA_WIDTH];
          end
       end
       else begin
          rd_full_data = rd_data_bus;
       end
    end
    endgenerate

    assign  rd_data = rd_full_data[c_DATA_WIDTH-1:0];

endmodule
