%% 清空
clear all; close all; clc;
gamma_value = 1/8.0;%
%% GPT之类的AI都可以快速生成
%% 打开文件
% Open file to write gamma lookup table
fpga_gamma = fopen('gamma_table.v', 'w');
fprintf(fpga_gamma, '//gamma_table\n');
fprintf(fpga_gamma, 'module gamma_lookuptable\n');
fprintf(fpga_gamma, '(\n');
fprintf(fpga_gamma, '   input\t\t[7:0]\tvideo_data,\n');
fprintf(fpga_gamma, '   output\t\treg[7:0]\tgamma_data\n');
fprintf(fpga_gamma, ');\n\n');
fprintf(fpga_gamma, 'always@(*)\n');
fprintf(fpga_gamma, 'begin\n');
fprintf(fpga_gamma, '\tcase(video_data)\n');

% Initialize gamma array
gamma_array = zeros(1, 256);
for i = 1:256
    gamma_array(1, i) = (255/255.^gamma_value) * (i-1).^gamma_value;
    gamma_array(1, i) = uint8(gamma_array(1, i));
    fprintf(fpga_gamma, '\t8''d%d : gamma_data = 8''d%d; \n',i-1,gamma_array(1, i));
end

fprintf(fpga_gamma, '\tendcase\n');
fprintf(fpga_gamma, 'end\n');
fprintf(fpga_gamma, '\nendmodule\n');
fclose(fpga_gamma);
