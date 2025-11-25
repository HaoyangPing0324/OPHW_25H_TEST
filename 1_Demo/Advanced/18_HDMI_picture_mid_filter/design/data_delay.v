module data_delay #(
    parameter NUMBER_OF_DELAYED_CLKS = 4,
    parameter COCLOR_DEPP = 8
)(
    input                             rstn,
    input                             clk,
    input      [3*COCLOR_DEPP-1:0]   data_in,
    
    output reg [3*COCLOR_DEPP-1:0]   data_out
);

generate
    genvar i;
    
    if (NUMBER_OF_DELAYED_CLKS == 0) begin
        // 无延迟：直接连接
        always @(*) begin
            data_out = data_in;
        end
    end
    else begin
        // 有延迟：使用寄存器链，长度为NUMBER_OF_DELAYED_CLKS
        reg [3*COCLOR_DEPP-1:0] data_delay [0:NUMBER_OF_DELAYED_CLKS-1];

        // 第一级延迟
        always @(posedge clk or negedge rstn) begin
            if (!rstn) begin
                data_delay[0] <= {3*COCLOR_DEPP{1'b0}};
            end else begin
                data_delay[0] <= data_in;
            end
        end

        // 中间延迟级（仅在N>1时生成）
        for (i = 1; i < NUMBER_OF_DELAYED_CLKS; i = i + 1) begin : data_delay_chain
            always @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    data_delay[i] <= {3*COCLOR_DEPP{1'b0}};
                end else begin
                    data_delay[i] <= data_delay[i-1];
                end
            end
        end

        // 输出直接取自延迟链的最后一级
        always @(*) begin
            data_out = data_delay[NUMBER_OF_DELAYED_CLKS-1];
        end
    end
endgenerate

endmodule