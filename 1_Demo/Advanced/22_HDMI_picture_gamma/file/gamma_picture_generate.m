clc;
clear all;
close all;

%% 读取原始图像
input_image_path = 'img.png';  % 请替换为您的图像路径
output_image_path = 'gamma_encoded_image.png';  % 输出图像路径

fprintf('正在读取图像: %s\n', input_image_path);

try
    original_image = imread(input_image_path);
    fprintf('图像读取成功!\n');
catch
    error('图像读取失败，请检查文件路径和格式');
end

% 显示图像信息
[rows, cols, channels] = size(original_image);
fprintf('图像尺寸: %d x %d, 通道数: %d\n', rows, cols, channels);

%% 设置Gamma参数
gamma_encode = 8;    % 编码Gamma值
gamma_decode = 1/8;  % 解码Gamma值（FPGA端使用）

fprintf('\n=== Gamma参数 ===\n');
fprintf('编码Gamma值: %.2f\n', gamma_encode);
fprintf('解码Gamma值: %.2f\n', gamma_decode);

%% 进行Gamma编码（使图像变暗）
fprintf('\n=== 正在进行Gamma编码 ===\n');

% 转换为double类型并归一化到[0,1]
original_double = im2double(original_image);

% 应用Gamma编码
gamma_encoded = original_double .^ gamma_encode;

% 转换回uint8格式
gamma_encoded_image = im2uint8(gamma_encoded);

fprintf('Gamma编码完成!\n');

%% 验证Gamma解码（在MATLAB中模拟FPGA处理）
fprintf('\n=== 验证Gamma解码 ===\n');

% 模拟FPGA的Gamma解码
decoded_double = im2double(gamma_encoded_image) .^ gamma_decode;
decoded_image = im2uint8(decoded_double);

% 计算解码后的质量
mse_value = mean((im2double(original_image(:)) - im2double(decoded_image(:))).^2);
psnr_value = 20 * log10(1 / sqrt(mse_value));
fprintf('解码验证 - MSE: %.6f, PSNR: %.2f dB\n', mse_value, psnr_value);

%% 显示结果对比
figure('Name', 'Gamma编码效果', 'NumberTitle', 'off', ...
       'Position', [100, 100, 1500, 500]);

% 显示原始图像
subplot(1, 4, 1);
imshow(original_image);
title('原始图像', 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示Gamma编码后的图像（需要校正的图像）
subplot(1, 4, 2);
imshow(gamma_encoded_image);
title(['Gamma编码图像 (γ=', num2str(gamma_encode), ')'], ...
      'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示解码后的图像
subplot(1, 4, 3);
imshow(decoded_image);
title('解码恢复图像', 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示亮度变化对比
subplot(1, 4, 4);
% 提取一行像素的亮度变化
if channels == 1
    sample_line = 100;  % 第100行
    original_line = double(original_image(sample_line, :));
    encoded_line = double(gamma_encoded_image(sample_line, :));
    decoded_line = double(decoded_image(sample_line, :));
    
    plot(1:cols, original_line, 'g-', 'LineWidth', 2, 'DisplayName', '原始');
    hold on;
    plot(1:cols, encoded_line, 'r-', 'LineWidth', 2, 'DisplayName', '编码后');
    plot(1:cols, decoded_line, 'b-', 'LineWidth', 2, 'DisplayName', '解码后');
    legend('show');
    title('像素亮度变化对比', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('像素位置');
    ylabel('亮度值');
    grid on;
else
    % 对于彩色图像，显示亮度通道
    original_gray = rgb2gray(original_image);
    encoded_gray = rgb2gray(gamma_encoded_image);
    decoded_gray = rgb2gray(decoded_image);
    
    sample_line = 100;
    original_line = double(original_gray(sample_line, :));
    encoded_line = double(encoded_gray(sample_line, :));
    decoded_line = double(decoded_gray(sample_line, :));
    
    plot(1:cols, original_line, 'g-', 'LineWidth', 2, 'DisplayName', '原始');
    hold on;
    plot(1:cols, encoded_line, 'r-', 'LineWidth', 2, 'DisplayName', '编码后');
    plot(1:cols, decoded_line, 'b-', 'LineWidth', 2, 'DisplayName', '解码后');
    legend('show');
    title('亮度通道变化对比', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('像素位置');
    ylabel('亮度值');
    grid on;
end

%% 保存处理后的图像
fprintf('\n=== 保存图像 ===\n');

try
    imwrite(gamma_encoded_image, output_image_path);
    fprintf('Gamma编码图像已保存: %s\n', output_image_path);
    
    % 保存解码验证图像
    imwrite(decoded_image, 'gamma_decoded_verification.png');
    fprintf('解码验证图像已保存: gamma_decoded_verification.png\n');
    
    % 保存Gamma参数信息
    info_filename = 'gamma_parameters.txt';
    fid = fopen(info_filename, 'w');
    fprintf(fid, 'Gamma校正参数信息\n');
    fprintf(fid, '==================\n\n');
    fprintf(fid, '处理时间: %s\n', datestr(now));
    fprintf(fid, '输入文件: %s\n', input_image_path);
    fprintf(fid, '输出文件: %s\n', output_image_path);
    fprintf(fid, '图像尺寸: %d x %d x %d\n', rows, cols, channels);
    fprintf(fid, '\nGamma参数:\n');
    fprintf(fid, '编码Gamma值: %.4f\n', gamma_encode);
    fprintf(fid, '解码Gamma值: %.4f (FPGA使用)\n', gamma_decode);
    fprintf(fid, '\n验证结果:\n');
    fprintf(fid, '均方误差: %.6f\n', mse_value);
    fprintf(fid, '峰值信噪比: %.2f dB\n', psnr_value);
    fprintf(fid, '\nFPGA处理说明:\n');
    fprintf(fid, '1. 对输入图像应用 Gamma = %.4f 的校正\n', gamma_decode);
    fprintf(fid, '2. 公式: output = input^(%.4f)\n', gamma_decode);
    fprintf(fid, '3. 处理后应恢复原始图像效果\n');
    fclose(fid);
    fprintf('参数信息已保存: %s\n', info_filename);
    
catch ME
    warning('文件保存失败: %s', ME.message);
end

%% 不同Gamma值效果对比
fprintf('\n=== 生成不同Gamma值对比 ===\n');

gamma_values = [1.5, 2.2, 3.0, 4.0];
titles = {'γ=1.5', 'γ=2.2', 'γ=3.0', 'γ=4.0'};

gamma_fig = figure('Name', '不同Gamma编码值效果', 'NumberTitle', 'off', ...
                  'Position', [150, 150, 1200, 800]);

for i = 1:4
    % 应用不同的Gamma编码
    test_encoded = original_double .^ gamma_values(i);
    test_encoded_image = im2uint8(test_encoded);
    
    subplot(2, 2, i);
    imshow(test_encoded_image);
    title([titles{i}, ' 编码'], 'FontSize', 11, 'FontWeight', 'bold');
end

sgtitle('不同Gamma编码值效果对比', 'FontSize', 14, 'FontWeight', 'bold');

% 保存对比图
try
    saveas(gamma_fig, 'gamma_comparison.png');
    fprintf('Gamma对比图已保存: gamma_comparison.png\n');
catch
    warning('对比图保存失败');
end

fprintf('\n=== 程序执行完成 ===\n');
fprintf('生成的 %s 就是需要FPGA进行Gamma校正的图像\n', output_image_path);
fprintf('FPGA校正公式: output_pixel = input_pixel^(%.4f)\n', gamma_decode);