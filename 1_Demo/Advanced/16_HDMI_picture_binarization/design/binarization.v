//延迟1个时钟信号
module binarization(

    input               clk             ,   
    input               rst_n           ,   
    input   [7:0]       y_in       ,

    output   [23:0]        data_bin            
);

//调一个好看的阈值。二分法k按效果，极其繁琐，而且每个图片阈值不一样，不能迁移。因此需要局部二值化
//parameter Binar_THRESHOLD = 128;
//parameter Binar_THRESHOLD = 192;
//parameter Binar_THRESHOLD = 160;
//parameter Binar_THRESHOLD = 144;
//parameter Binar_THRESHOLD = 152;
//parameter Binar_THRESHOLD = 156;
//parameter Binar_THRESHOLD = 158;
parameter Binar_THRESHOLD = 159;

reg pix;

//二值化
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        pix <= 1'b0;
    else if(y_in > Binar_THRESHOLD)  //阈值
        pix <= 1'b1;
    else
        pix <= 1'b0;
end

assign data_bin = {24{pix}};

endmodule 