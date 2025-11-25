

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
module ipm2l_spram_v1_8_blk_mem_gen_0 #(
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
`include "blk_mem_gen_0_init_param.v"

    localparam  c_WR_BYTE_WIDTH = c_WR_BYTE_EN ? c_DATA_WIDTH/(c_BE_WIDTH==0 ? 1 : c_BE_WIDTH) : (c_DATA_WIDTH%9 ==0 ? 9 : 8 );

    //DRM_DATA_WIDTH is the  port parameter  of DRM
    localparam  DRM_DATA_WIDTH  = 1;

    localparam  DATA_LOOP_NUM  = (c_DATA_WIDTH%DRM_DATA_WIDTH == 0) ? (c_DATA_WIDTH/DRM_DATA_WIDTH):(c_DATA_WIDTH/DRM_DATA_WIDTH + 1);

    localparam  Q_DATA_WIDTH  = 1;
    //DRM_ADDR_WIDTH is the ADDR_WIDTH of INSTANCE DRM primitives
    localparam  DRM_ADDR_WIDTH = 16;

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
    localparam  MASK_NUM  = ( ADDR_LOOP_NUM >8 ) ? 4 : 8;

    //parameter  check
    initial begin
       if(c_ADDR_WIDTH>20 || c_ADDR_WIDTH<9 ) begin
          $display("IPSpecCheck: 04030237 ipm2l_flex_spram parameter setting error !!!: c_ADDR_WIDTH must between 9-20 when DRM Resource is 64K")/* PANGO PAP_WARNING */;
//          $finish;
       end
       else if( c_DATA_WIDTH>1152 || c_DATA_WIDTH<1 ) begin
          $display("IPSpecCheck: 04030238 ipm2l_flex_spram parameter setting error !!!: c_DATA_WIDTH must between 1-1152")/* PANGO PAP_WARNING */;
//          $finish;
       end
//       else if( (2**c_ADDR_WIDTH) * c_DATA_WIDTH>1152*1024 ) begin
//          $display("IPSpecCheck: 04030239 ipm2l_flex_spram parameter setting error !!!: ipml_flex_ram must less than  1152k")/* PANGO PAP_ERROR */;
//          $finish;
//       end
       else if(c_OUTPUT_REG!=1 && c_OUTPUT_REG!=0 ) begin
          $display("IPSpecCheck: 04030240 ipm2l_flex_spram parameter setting error !!!: c_OUTPUT_REG must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if ( c_FAB_REG!=1 && c_FAB_REG!=0  ) begin
           $display("IPSpecCheck: 04030254 ipm2l_flex_spram parameter setting error !!!: c_FAB_REGmust be 0 or 1")/* PANGO PAP_ERROR */;
           $finish;
       end
       else if ( c_RD_OCE_EN!=0 && c_RD_OCE_EN!=1 ) begin
          $display("IPSpecCheck: 04030241 ipm2l_flex_spram parameter setting error !!!: c_RD_OCE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if ( c_CLK_OR_POL_INV!=0 && c_CLK_OR_POL_INV!=1 ) begin
          $display("IPSpecCheck: 04030242 ipm2l_flex_spram parameter setting error !!!: c_CLK_OR_POL_INV must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if( c_RD_OCE_EN==1 && (c_OUTPUT_REG==0 && c_FAB_REG==0) ) begin
           $display("IPSpecCheck: 04030243 ipm2l_flex_spram parameter setting error !!!: c_OUTPUT_REG and c_FAB_REG could not be 0 at same time when c_RD_OCE_EN is 1")/* PANGO PAP_ERROR */;
           $finish;
       end
       else if( c_CLK_OR_POL_INV==1 && (c_OUTPUT_REG==0 && c_FAB_REG==0) ) begin
           $display("IPSpecCheck: 04030244 ipm2l_flex_spram parameter setting error !!!: c_OUTPUT_REG and c_FAB_REG could not be 0 at same time when c_CLK_OR_POL_INV is 1")/* PANGO PAP_ERROR */;
           $finish;
       end
       else if ( c_CLK_EN!=0 && c_CLK_EN!=1 ) begin
          $display("IPSpecCheck: 04030245 ipm2l_flex_spram parameter setting error !!!: c_CLK_EN must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if ( c_ADDR_STROBE_EN!=0 && c_ADDR_STROBE_EN!=1 ) begin
          $display("IPSpecCheck: 04030246 ipm2l_flex_spram parameter setting error !!!: c_ADDR_STROBE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_RESET_TYPE!="ASYNC" && c_RESET_TYPE!="SYNC") begin
          $display("IPSpecCheck: 04030047 ipm2l_flex_spram parameter setting error !!!: c_RESET_TYPE must be ASYNC or SYNC")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_POWER_OPT!=1 && c_POWER_OPT!=0 ) begin
          $display("IPSpecCheck: 04030248 ipm2l_flex_spram parameter setting error !!!: c_POWER_OPT must be 0 or 1")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_INIT_FORMAT!="BIN" && c_INIT_FORMAT!="HEX" ) begin
          $display("IPSpecCheck: 04030249 ipm2l_flex_spram parameter setting error !!!: c_INIT_FORMAT must be bin or hex ")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_WR_BYTE_EN!=0) begin
          $display("IPSpecCheck: 04030250 ipm2l_flex_spram parameter setting error !!!: c_WR_BYTE_EN must be 0 when DRM Resource is 64K")/* PANGO PAP_ERROR */;
          $finish;
       end
       else if(c_WRITE_MODE!="NORMAL_WRITE" && c_WRITE_MODE!="TRANSPARENT_WRITE" && c_WRITE_MODE!="READ_BEFORE_WRITE") begin
          $display("IPSpecCheck: 04030251 ipm2l_flex_spram parameter setting error !!!: c_WRITE_MODE must be NORMAL_WRITE or TRANSPARENT_WRITE or READ_BEFORE_WRITE")/* PANGO PAP_ERROR */;
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
    wire [8*(CAS_DATA_WIDTH/WR_BYTE_WIDTH)-1 : 0]   wr_byte_en_bus;
    reg  [8*(CAS_DATA_WIDTH/WR_BYTE_WIDTH)-1 : 0]   wr_byte_en_bus_m;
    reg  [2*(CAS_DATA_WIDTH/WR_BYTE_WIDTH)-1 : 0]   wr_byte_en_bus_b;

    wire  [DATA_LOOP_NUM*ADDR_LOOP_NUM-1:0]     cas_caout        ;
    wire  [DATA_LOOP_NUM*ADDR_LOOP_NUM-1:0]     cas_cbout        ;

    //********************************************************************************************************************************************************
    //write data mux
    assign  wr_data_bus[CAS_DATA_WIDTH-1:0] = {{(CAS_DATA_WIDTH-c_DATA_WIDTH){1'b0}},wr_data[c_DATA_WIDTH-1:0]};

    assign  addr_bus[ADDR_WIDTH-1:0] = {{(ADDR_WIDTH-c_ADDR_WIDTH){1'b0}},addr[c_ADDR_WIDTH-1:0]};

    //generate drm_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
    integer gen_wa;
    generate
    always@(*) begin
       for(gen_wa=0;gen_wa < DATA_LOOP_NUM;gen_wa = gen_wa +1 ) begin
          case(DRM_DATA_WIDTH)
             1     : begin
                         drm_addr[gen_wa*16 +: 16]   = addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0];
                         drm_b_addr[gen_wa*16 +: 16] = addr_bus[(ADDR_WIDTH-CS_ADDR_WIDTH-1):0];
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
    endgenerate

    wire [36*DATA_LOOP_NUM*ADDR_LOOP_NUM-1:0]  QA_bus;
    wire [36*DATA_LOOP_NUM*ADDR_LOOP_NUM-1:0]  QB_bus;
    wire [36*DATA_LOOP_NUM-1:0]                DA_bus;
    wire [36*DATA_LOOP_NUM-1:0]                DB_bus;

    integer  drm_d_i;
    generate
    always@(*) begin
       for (drm_d_i = 0; drm_d_i <DATA_LOOP_NUM; drm_d_i = drm_d_i+1) begin
          da_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH] = wr_data_bus[drm_d_i*DRM_DATA_WIDTH +:DRM_DATA_WIDTH];
          db_data_bus[drm_d_i*Q_DATA_WIDTH +:Q_DATA_WIDTH] = 'b0;
       end
    end
    endgenerate

    localparam RAM_MODE_SEL       = (c_RAM_MODE == "ROM") ? "ROM" : "SINGLE_PORT";
    localparam DRM_DATA_WIDTH_SEL = DRM_DATA_WIDTH;

    //generate constructs: ADDR_LOOP to cascade request address  and  DATA LOOP to cascade request data
    genvar gen_i,gen_j;
    generate
    for(gen_j=0;gen_j<ADDR_LOOP_NUM;gen_j=gen_j+1) begin:ADDR_LOOP
        for(gen_i=0;gen_i<DATA_LOOP_NUM;gen_i=gen_i+1) begin:DATA_LOOP
            localparam [2:0] CSA_MASK     = (gen_j%MASK_NUM);
            localparam [2:0] CSB_MASK     = (gen_j%MASK_NUM);
            localparam [2:0] CSA_MASK_SEL = CSA_MASK;
            localparam [2:0] CSB_MASK_SEL = CSB_MASK;

            assign  qa_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:Q_DATA_WIDTH];
            assign  DA_bus[gen_i*36 +:Q_DATA_WIDTH] = da_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];
            assign  qb_data_bus[gen_i*Q_DATA_WIDTH+gen_j*Q_CAS_DATA_WIDTH +:Q_DATA_WIDTH] = QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:Q_DATA_WIDTH];
            assign  DB_bus[gen_i*36 +:Q_DATA_WIDTH] = db_data_bus[gen_i*Q_DATA_WIDTH +:Q_DATA_WIDTH];

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
                .CSA_MASK                 ( CSA_MASK_SEL             ),
                .CSB_MASK                 ( CSB_MASK_SEL             ),
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
                .RAM_CASCADE              ( "UPPER"                  ),
                .ECC_WRITE_EN             ( "FALSE"                  ),
                .ECC_READ_EN              ( "FALSE"                  ),
                .BLOCK_X                  ( gen_i                    ),
                .BLOCK_Y                  ( gen_j                    ),
                .RAM_ADDR_WIDTH           ( ADDR_WIDTH               ),
                .RAM_DATA_WIDTH           ( CAS_DATA_WIDTH           ),
                .INIT_FORMAT              ( c_INIT_FORMAT            )
            ) U_GTP_DRM36K_E1_1 (
                .DOA                      ( QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:36]  ),
                .ADDRA                    ( drm_addr[gen_i*16 +:16]                         ),
                .ADDRA_HOLD               ( addr_strobe                                     ),
                .BWEA                     ( 8'b1111_1111                                    ),
                .DIA                      ( DA_bus[gen_i*36 +:36]                           ),
                .CSA                      ( {cs_bit2_bus[gen_j], cs_bit1_bus[gen_j], cs_bit0}      ),
                .WEA                      ( wr_en                                           ),
                .CLKA                     ( clk                                             ),
                .CEA                      ( clk_en                                          ),
                .ORCEA                    ( rd_oce                                          ),
                .RSTA                     ( rst                                             ),
                .CINA                     ( cas_caout[gen_i + gen_j*DATA_LOOP_NUM +:1]      ),
                .COUTA                    (                                                 ),

                .DOB                      ( QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:36]  ),
                .ADDRB                    ( drm_b_addr[15:0]                                ),
                .ADDRB_HOLD               ( addr_strobe                                     ),
                .BWEB                     ( 4'b1111                                         ),
                .DIB                      ( DB_bus[gen_i*36 +:36]                           ),
                .CSB                      ( 3'b000                                          ),
                .WEB                      ( 1'b0                                            ),
                .CLKB                     ( clk                                             ),
                .CEB                      ( 1'b0                                            ),
                .ORCEB                    ( rd_oce                                          ),
                .RSTB                     ( rst                                             ),
                .CINB                     ( cas_cbout[gen_i + gen_j*DATA_LOOP_NUM +:1]      ),
                .COUTB                    (                                                 ),

                .INJECT_SBITERR           (                                                 ),
                .INJECT_DBITERR           (                                                 ),
                .ECC_SBITERR              (                                                 ),
                .ECC_DBITERR              (                                                 ),
                .ECC_RDADDR               (                                                 ),
                .ECC_PARITY               (                                                 )
            );

            GTP_DRM36K_E1 # (

                .INIT_00                  (INIT_80[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_01                  (INIT_81[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_02                  (INIT_82[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_03                  (INIT_83[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_04                  (INIT_84[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_05                  (INIT_85[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_06                  (INIT_86[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_07                  (INIT_87[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_08                  (INIT_88[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_09                  (INIT_89[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0A                  (INIT_8A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0B                  (INIT_8B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0C                  (INIT_8C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0D                  (INIT_8D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0E                  (INIT_8E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_0F                  (INIT_8F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_10                  (INIT_90[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_11                  (INIT_91[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_12                  (INIT_92[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_13                  (INIT_93[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_14                  (INIT_94[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_15                  (INIT_95[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_16                  (INIT_96[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_17                  (INIT_97[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_18                  (INIT_98[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_19                  (INIT_99[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1A                  (INIT_9A[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1B                  (INIT_9B[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1C                  (INIT_9C[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1D                  (INIT_9D[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1E                  (INIT_9E[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_1F                  (INIT_9F[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_20                  (INIT_A0[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_21                  (INIT_A1[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_22                  (INIT_A2[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_23                  (INIT_A3[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_24                  (INIT_A4[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_25                  (INIT_A5[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_26                  (INIT_A6[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_27                  (INIT_A7[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_28                  (INIT_A8[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_29                  (INIT_A9[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2A                  (INIT_AA[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2B                  (INIT_AB[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2C                  (INIT_AC[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2D                  (INIT_AD[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2E                  (INIT_AE[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_2F                  (INIT_AF[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_30                  (INIT_B0[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_31                  (INIT_B1[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_32                  (INIT_B2[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_33                  (INIT_B3[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_34                  (INIT_B4[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_35                  (INIT_B5[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_36                  (INIT_B6[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_37                  (INIT_B7[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_38                  (INIT_B8[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_39                  (INIT_B9[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3A                  (INIT_BA[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3B                  (INIT_BB[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3C                  (INIT_BC[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3D                  (INIT_BD[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3E                  (INIT_BE[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_3F                  (INIT_BF[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_40                  (INIT_C0[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_41                  (INIT_C1[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_42                  (INIT_C2[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_43                  (INIT_C3[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_44                  (INIT_C4[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_45                  (INIT_C5[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_46                  (INIT_C6[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_47                  (INIT_C7[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_48                  (INIT_C8[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_49                  (INIT_C9[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4A                  (INIT_CA[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4B                  (INIT_CB[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4C                  (INIT_CC[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4D                  (INIT_CD[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4E                  (INIT_CE[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_4F                  (INIT_CF[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_50                  (INIT_D0[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_51                  (INIT_D1[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_52                  (INIT_D2[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_53                  (INIT_D3[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_54                  (INIT_D4[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_55                  (INIT_D5[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_56                  (INIT_D6[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_57                  (INIT_D7[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_58                  (INIT_D8[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_59                  (INIT_D9[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5A                  (INIT_DA[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5B                  (INIT_DB[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5C                  (INIT_DC[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5D                  (INIT_DD[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5E                  (INIT_DE[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_5F                  (INIT_DF[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_60                  (INIT_E0[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_61                  (INIT_E1[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_62                  (INIT_E2[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_63                  (INIT_E3[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_64                  (INIT_E4[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_65                  (INIT_E5[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_66                  (INIT_E6[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_67                  (INIT_E7[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_68                  (INIT_E8[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_69                  (INIT_E9[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6A                  (INIT_EA[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6B                  (INIT_EB[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6C                  (INIT_EC[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6D                  (INIT_ED[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6E                  (INIT_EE[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_6F                  (INIT_EF[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_70                  (INIT_F0[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_71                  (INIT_F1[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_72                  (INIT_F2[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_73                  (INIT_F3[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_74                  (INIT_F4[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_75                  (INIT_F5[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_76                  (INIT_F6[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_77                  (INIT_F7[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_78                  (INIT_F8[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_79                  (INIT_F9[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7A                  (INIT_FA[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7B                  (INIT_FB[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7C                  (INIT_FC[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7D                  (INIT_FD[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7E                  (INIT_FE[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),
                .INIT_7F                  (INIT_FF[(gen_j * DATA_LOOP_NUM + gen_i)*288 +: 288]),

                .GRS_EN                   ( "FALSE"                  ),
                .CSA_MASK                 ( CSA_MASK_SEL             ),
                .CSB_MASK                 ( CSB_MASK_SEL             ),
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
                .RAM_CASCADE              ( "LOWER"                  ),
                .ECC_WRITE_EN             ( "FALSE"                  ),
                .ECC_READ_EN              ( "FALSE"                  ),
                .BLOCK_X                  ( gen_i                    ),
                .BLOCK_Y                  ( gen_j                    ),
                .RAM_ADDR_WIDTH           ( ADDR_WIDTH               ),
                .RAM_DATA_WIDTH           ( CAS_DATA_WIDTH           ),
                .INIT_FORMAT              ( c_INIT_FORMAT            )
            ) U_GTP_DRM36K_E1_0 (
                .DOA                      (                                                 ),
                .ADDRA                    ( drm_addr[gen_i*16 +:16]                         ),
                .ADDRA_HOLD               ( addr_strobe                                     ),
                .BWEA                     ( 8'b1111_1111                                    ),
                .DIA                      ( DA_bus[gen_i*36 +:36]                           ),
                .CSA                      ( {cs_bit2_bus[gen_j], cs_bit1_bus[gen_j], cs_bit0}      ),
                .WEA                      ( wr_en                                           ),
                .CLKA                     ( clk                                             ),
                .CEA                      ( clk_en                                          ),
                .ORCEA                    ( rd_oce                                          ),
                .RSTA                     ( rst                                             ),
                .CINA                     (                                                 ),
                .COUTA                    ( cas_caout[gen_i + gen_j*DATA_LOOP_NUM +:1]      ),

                .DOB                      (                                                 ),
                .ADDRB                    ( drm_b_addr[15:0]                                ),
                .ADDRB_HOLD               ( addr_strobe                                     ),
                .BWEB                     ( 4'b1111                                         ),
                .DIB                      ( DB_bus[gen_i*36 +:36]                           ),
                .CSB                      ( 3'b000                                          ),
                .WEB                      ( 1'b0                                            ),
                .CLKB                     ( clk                                             ),
                .CEB                      ( 1'b0                                            ),
                .ORCEB                    ( rd_oce                                          ),
                .RSTB                     ( rst                                             ),
                .CINB                     (                                                 ),
                .COUTB                    ( cas_cbout[gen_i + gen_j*DATA_LOOP_NUM +:1]      ),

                .INJECT_SBITERR           (                                                 ),
                .INJECT_DBITERR           (                                                 ),
                .ECC_SBITERR              (                                                 ),
                .ECC_DBITERR              (                                                 ),
                .ECC_RDADDR               (                                                 ),
                .ECC_PARITY               (                                                 )
            );

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
