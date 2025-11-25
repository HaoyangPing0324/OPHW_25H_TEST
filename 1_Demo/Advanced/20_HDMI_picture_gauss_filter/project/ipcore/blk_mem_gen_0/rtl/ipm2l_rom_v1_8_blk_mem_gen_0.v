

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
// Filename:ipm2l_rom.v
//////////////////////////////////////////////////////////////////////////////

module ipm2l_rom_v1_8_blk_mem_gen_0 #(
    parameter  c_CAS_MODE           = "18K"        ,  // "18K", "36K", "64K"
    parameter  c_ADDR_WIDTH         = 10           ,
    parameter  c_DATA_WIDTH         = 32           ,
    parameter  c_OUTPUT_REG         = 0            ,
    parameter  c_FAB_REG            = 0            ,
    parameter  c_RD_OCE_EN          = 0            ,
    parameter  c_CLK_EN             = 0            ,
    parameter  c_ADDR_STROBE_EN     = 0            ,
    parameter  c_RESET_TYPE         = "ASYNC_RESET",
    parameter  c_POWER_OPT          = 0            ,
    parameter  c_CLK_OR_POL_INV     = 0            ,
    parameter  c_INIT_FILE          = "NONE"       ,
    parameter  c_INIT_FORMAT        = "BIN"
) (
    input  wire [c_ADDR_WIDTH-1 : 0]  addr        ,
    output wire [c_DATA_WIDTH-1 : 0]  rd_data     ,
    input  wire                       clk         ,
    input  wire                       clk_en      ,
    input  wire                       addr_strobe ,
    input  wire                       rst         ,
    input  wire                       rd_oce
);

ipm2l_spram_v1_8_blk_mem_gen_0 #(
    .c_CAS_MODE             ( c_CAS_MODE        ),
    .c_ADDR_WIDTH           ( c_ADDR_WIDTH      ),
    .c_DATA_WIDTH           ( c_DATA_WIDTH      ),
    .c_OUTPUT_REG           ( c_OUTPUT_REG      ),
    .c_FAB_REG              ( c_FAB_REG         ),
    .c_RD_OCE_EN            ( c_RD_OCE_EN       ),
    .c_ADDR_STROBE_EN       ( c_ADDR_STROBE_EN  ),
    .c_CLK_EN               ( c_CLK_EN          ),
    .c_RESET_TYPE           ( c_RESET_TYPE      ),
    .c_POWER_OPT            ( c_POWER_OPT       ),
    .c_CLK_OR_POL_INV       ( c_CLK_OR_POL_INV  ),
    .c_INIT_FILE            ( c_INIT_FILE       ),
    .c_INIT_FORMAT          ( c_INIT_FORMAT     ),
    .c_WR_BYTE_EN           ( 0                 ),
    .c_BE_WIDTH             ( 1                 ),
    .c_RAM_MODE             ( "ROM"             ),
    .c_WRITE_MODE           ( "NORMAL_WRITE"    )
) U_ipm2l_spram (
    .addr        (addr),
    .wr_data     (),
    .rd_data     (rd_data),
    .wr_en       (1'b0),
    .clk         (clk),
    .clk_en      (clk_en),
    .addr_strobe (addr_strobe),
    .rst         (rst),
    .wr_byte_en  (),
    .rd_oce      (rd_oce)
);

endmodule
