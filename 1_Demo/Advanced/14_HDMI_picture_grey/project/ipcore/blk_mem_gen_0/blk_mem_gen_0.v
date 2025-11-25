
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
// Library:
// Filename:blk_mem_gen_0.v
//////////////////////////////////////////////////////////////////////////////

module blk_mem_gen_0 (
     addr        ,
     rd_data     ,
     clk         ,
     
     rst
);


localparam CAS_MODE = "64K" ; // @IPC enum 18K,36K,64K

localparam POWER_OPT = 0 ; // @IPC bool

localparam ADDR_WIDTH = 16 ; // @IPC int 9,20

localparam DATA_WIDTH = 24 ; // @IPC int 1,1152

localparam CLK_EN  = 0 ; // @IPC bool

localparam ADDR_STROBE_EN  = 0 ; // @IPC bool

localparam RD_OCE_EN = 0 ; // @IPC bool

localparam OUTPUT_REG = 0 ; // @IPC bool

localparam CLK_OR_POL_INV = 0 ; // @IPC bool

localparam FAB_REG = 0 ; // @IPC bool

localparam RESET_TYPE = "ASYNC" ; // @IPC enum SYNC,ASYNC

localparam INIT_EN = 1 ; // @IPC bool

localparam INIT_FILE = "E:/User/Files/project_self/OPHW_25H/OPHW_25H_TEST/1_Demo/Advanced/14_HDMI_picture_grey/file/img.dat" ; // @IPC string

localparam INIT_FORMAT = "HEX" ; // @IPC enum BIN,HEX

localparam RST_VAL_EN = 0 ; // @IPC bool


input  [ADDR_WIDTH-1 : 0]     addr        ;
output [DATA_WIDTH-1 : 0]     rd_data     ;
input                         clk         ;

input                         rst         ;


wire [ADDR_WIDTH-1 : 0]       addr        ;
wire [DATA_WIDTH-1 : 0]       rd_data     ;
wire                          clk         ;
wire                          clk_en      ;
wire                          addr_strobe ;
wire                          rst         ;
wire                          rd_oce      ;

wire                          rd_oce_mux      ;
wire                          clk_en_mux      ;
wire                          addr_strobe_mux ;

wire                          rd_oce_mux2d    ;
wire                          rd_oce_mux2f    ;

wire [DATA_WIDTH-1 : 0]       rd_data_d;
reg  [DATA_WIDTH-1 : 0]       fab_reg_invt;
reg  [DATA_WIDTH-1 : 0]       fab_reg;


assign rd_oce_mux2d    = ((FAB_REG       == 1) && (OUTPUT_REG == 1)) ? 1 :
                          (OUTPUT_REG    == 1) ? ((RD_OCE_EN  == 1)  ? rd_oce : 1'b1) : 1'b0 ;
assign rd_oce_mux2f    =  (FAB_REG       == 1) ? ((RD_OCE_EN  == 1)  ? rd_oce : 1'b1) : 1'b0 ;
assign clk_en_mux      = (CLK_EN         == 1) ? clk_en      : 1'b1 ;
assign addr_strobe_mux = (ADDR_STROBE_EN == 1) ? addr_strobe : 1'b0 ;


//ipml_rom IP instance
ipm2l_rom_v1_8_blk_mem_gen_0 #(
    .c_CAS_MODE         ( CAS_MODE              ),
    .c_ADDR_WIDTH       ( ADDR_WIDTH            ),
    .c_DATA_WIDTH       ( DATA_WIDTH            ),
    .c_OUTPUT_REG       ( OUTPUT_REG            ),
    .c_RD_OCE_EN        ( RD_OCE_EN             ),
    .c_FAB_REG          (FAB_REG                ),
    .c_CLK_EN           ( CLK_EN                ),
    .c_ADDR_STROBE_EN   ( ADDR_STROBE_EN        ),
    .c_RESET_TYPE       ( RESET_TYPE            ),
    .c_POWER_OPT        ( POWER_OPT             ),
    .c_CLK_OR_POL_INV   ( CLK_OR_POL_INV        ),
    .c_INIT_FILE        ( "NONE"                ),
    .c_INIT_FORMAT      ( INIT_FORMAT           )
) U_ipm2l_rom_blk_mem_gen_0 (
    .addr               ( addr                  ),
    
    .rd_data            ( rd_data               ),
    
    .clk                ( clk                   ),
    .clk_en             ( clk_en_mux            ),
    .addr_strobe        ( addr_strobe_mux       ),
    .rst                ( rst                   ),
    .rd_oce             ( rd_oce_mux2d          )
);


generate
    if (FAB_REG == 1) begin

        assign rd_data = (FAB_REG == 1) ? ((CLK_OR_POL_INV == 1) ? fab_reg_invt : fab_reg) : rd_data_d ;
        if (CLK_OR_POL_INV == 1) begin
            always @(negedge clk or posedge rst) begin
                if (rst)
                    fab_reg_invt      <= {DATA_WIDTH{1'b0}};
                else if (rd_oce_mux2f)
                    fab_reg_invt      <= rd_data_d;
            end
        end
        else begin
            always @(posedge clk or posedge rst) begin
                if (rst)
                    fab_reg           <= {DATA_WIDTH{1'b0}};
                else if (rd_oce_mux2f)
                    fab_reg           <= rd_data_d;
            end
        end
    end
endgenerate

endmodule
