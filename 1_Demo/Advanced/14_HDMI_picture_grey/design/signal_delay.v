module signal_delay #(
    parameter NUMBER_OF_DELAYED_CLKS = 4
)(
    input                             rstn,
    input                             clk,
    input                             vs_in, 
    input                             hs_in, 
    input                             de_in,
    
    output reg                        vs_out, 
    output reg                        hs_out, 
    output reg                        de_out
);

generate
    genvar i;
    
    if (NUMBER_OF_DELAYED_CLKS == 0) begin
        // 无延迟：直接连接
        always @(*) begin
            vs_out = vs_in;
            hs_out = hs_in;
            de_out = de_in;
        end
    end
    else begin
        // 有延迟：使用寄存器链，长度为NUMBER_OF_DELAYED_CLKS
        reg [0:NUMBER_OF_DELAYED_CLKS-1] vs_delay, hs_delay, de_delay;

        // 第一级延迟
        always @(posedge clk or negedge rstn) begin
            if (!rstn) begin
                vs_delay[0] <= 1'b0;
                hs_delay[0] <= 1'b0;
                de_delay[0] <= 1'b0;
            end else begin
                vs_delay[0] <= vs_in;
                hs_delay[0] <= hs_in;
                de_delay[0] <= de_in;
            end
        end

        // 中间延迟级（仅在N>1时生成）
        for (i = 1; i < NUMBER_OF_DELAYED_CLKS; i = i + 1) begin : delay_chain_gen
            always @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    vs_delay[i] <= 1'b0;
                    hs_delay[i] <= 1'b0;
                    de_delay[i] <= 1'b0;
                end else begin
                    vs_delay[i] <= vs_delay[i-1];
                    hs_delay[i] <= hs_delay[i-1];
                    de_delay[i] <= de_delay[i-1];
                end
            end
        end

        // 输出直接取自延迟链的最后一级
        always @(*) begin
            vs_out = vs_delay[NUMBER_OF_DELAYED_CLKS-1];
            hs_out = hs_delay[NUMBER_OF_DELAYED_CLKS-1];
            de_out = de_delay[NUMBER_OF_DELAYED_CLKS-1];
        end
    end
endgenerate

endmodule