clc;
clear all;
close all;

%% 读取图像文件 - 请替换为您自己的图像路径
input_image_path = 'img.png';  % 输入图像路径
output_image_path = 'gaussian_noise_image.png';  % 输出图像路径

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

%% 设置高斯噪声参数
mean_value = 0;      % 均值（通常设为0）
variance = 0.30;     % 方差（控制噪声强度，建议范围：0.01-0.05）
noise_intensity = sqrt(variance);  % 标准差

fprintf('\n=== 高斯噪声参数 ===\n');
fprintf('噪声均值: %.2f\n', mean_value);
fprintf('噪声方差: %.3f\n', variance);
fprintf('噪声强度(标准差): %.3f\n', noise_intensity);

%% 添加高斯噪声
fprintf('\n=== 正在添加高斯噪声 ===\n');

% 创建图像副本
noisy_image = im2double(original_image);  % 转换为double类型便于计算

% 为每个通道添加高斯噪声
for ch = 1:channels
    % 生成高斯噪声
    gaussian_noise = noise_intensity * randn(rows, cols) + mean_value;
    
    % 添加噪声到当前通道
    noisy_channel = noisy_image(:, :, ch) + gaussian_noise;
    
    % 限制像素值在[0,1]范围内
    noisy_channel = max(0, min(1, noisy_channel));
    
    noisy_image(:, :, ch) = noisy_channel;
end

% 转换回uint8格式
noisy_image = im2uint8(noisy_image);

fprintf('高斯噪声添加完成!\n');

%% 计算图像质量指标
fprintf('\n=== 图像质量分析 ===\n');

original_double = im2double(original_image);
noisy_double = im2double(noisy_image);

% 计算均方误差 (MSE)
mse_value = mean((original_double(:) - noisy_double(:)).^2);
fprintf('均方误差 (MSE): %.6f\n', mse_value);

% 计算峰值信噪比 (PSNR)
if mse_value == 0
    psnr_value = Inf;
else
    psnr_value = 20 * log10(1 / sqrt(mse_value));
end
fprintf('峰值信噪比 (PSNR): %.2f dB\n', psnr_value);

%% 显示结果对比
figure('Name', '高斯噪声添加结果', 'NumberTitle', 'off', ...
       'Position', [100, 100, 1200, 500]);

% 显示原始图像
subplot(1, 3, 1);
imshow(original_image);
title('原始图像', 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示噪声图像
subplot(1, 3, 2);
imshow(noisy_image);
title(['高斯噪声图像 (方差: ', num2str(variance), ')'], ...
      'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示噪声分布
subplot(1, 3, 3);
if channels == 1
    noise_map = abs(noisy_double - original_double);
else
    noise_map = mean(abs(noisy_double - original_double), 3);
end
imshow(noise_map * 10);  % 放大显示噪声
title('噪声分布 (放大10倍)', 'FontSize', 12, 'FontWeight', 'bold');
axis image;
colormap(jet);
colorbar;

%% 保存处理后的图像
fprintf('\n=== 保存图像 ===\n');

try
    imwrite(noisy_image, output_image_path);
    fprintf('高斯噪声图像已保存: %s\n', output_image_path);
    
    % 保存质量信息到文本文件
    info_filename = 'gaussian_noise_info.txt';
    fid = fopen(info_filename, 'w');
    fprintf(fid, '高斯噪声处理信息\n');
    fprintf(fid, '================\n\n');
    fprintf(fid, '处理时间: %s\n', datestr(now));
    fprintf(fid, '输入文件: %s\n', input_image_path);
    fprintf(fid, '输出文件: %s\n', output_image_path);
    fprintf(fid, '图像尺寸: %d x %d x %d\n', rows, cols, channels);
    fprintf(fid, '噪声均值: %.2f\n', mean_value);
    fprintf(fid, '噪声方差: %.3f\n', variance);
    fprintf(fid, '均方误差: %.6f\n', mse_value);
    fprintf(fid, '峰值信噪比: %.2f dB\n', psnr_value);
    fclose(fid);
    fprintf('处理信息已保存: %s\n', info_filename);
    
catch ME
    warning('文件保存失败: %s', ME.message);
end

%% 不同方差对比（可选）
fprintf('\n=== 生成不同方差对比图 ===\n');

variance_levels = [0.005, 0.01, 0.02, 0.03, 0.05, 0.1];
titles = {'方差=0.005', '方差=0.01', '方差=0.02', '方差=0.03', '方差=0.05', '方差=0.1'};

compare_fig = figure('Name', '不同方差高斯噪声对比', 'NumberTitle', 'off', ...
                    'Position', [150, 150, 1200, 800]);

for i = 1:6
    % 为每个方差级别创建噪声图像
    test_noisy = im2double(original_image);
    current_variance = variance_levels(i);
    current_intensity = sqrt(current_variance);
    
    for ch = 1:channels
        gaussian_noise = current_intensity * randn(rows, cols) + mean_value;
        noisy_channel = test_noisy(:, :, ch) + gaussian_noise;
        noisy_channel = max(0, min(1, noisy_channel));
        test_noisy(:, :, ch) = noisy_channel;
    end
    
    subplot(2, 3, i);
    imshow(im2uint8(test_noisy));
    title(titles{i}, 'FontSize', 11, 'FontWeight', 'bold');
end

sgtitle('不同方差高斯噪声效果对比', 'FontSize', 14, 'FontWeight', 'bold');

% 保存对比图
try
    saveas(compare_fig, 'gaussian_noise_comparison.png');
    fprintf('噪声对比图已保存: gaussian_noise_comparison.png\n');
catch
    warning('对比图保存失败');
end

fprintf('\n=== 程序执行完成 ===\n');