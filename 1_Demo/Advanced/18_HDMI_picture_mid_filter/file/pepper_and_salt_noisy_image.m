clc;
clear all;
close all;

%% 图像读取和预处理
fprintf('=== 椒盐噪声添加程序 ===\n');

% 读取图像文件 - 请替换为您自己的图像路径
image_path = 'img.png';  % 支持bmp/png/jpg等格式
fprintf('正在读取图像: %s\n', image_path);

try
    original_image = imread(image_path);
    fprintf('图像读取成功!\n');
catch
    error('图像读取失败，请检查文件路径和格式');
end

% 显示图像信息
[rows, cols, channels] = size(original_image);
fprintf('图像尺寸: %d x %d, 通道数: %d\n', rows, cols, channels);
fprintf('图像数据类型: %s\n', class(original_image));

% 如果图像是索引图像，转换为RGB
if ndims(original_image) == 2
    fprintf('检测到灰度图像\n');
elseif channels == 3
    fprintf('检测到彩色图像\n');
end

%% 参数设置
noise_density = 0.20;  % 噪声密度 (0.01 = 1%, 0.1 = 10%, 可根据需要调整)
output_filename = 'noisy_image.png';  % 输出文件名
output_quality = 95;  % PNG输出质量 (1-100)

fprintf('\n=== 噪声参数设置 ===\n');
fprintf('噪声密度: %.1f%%\n', noise_density * 100);
fprintf('输出文件: %s\n', output_filename);

%% 添加椒盐噪声
fprintf('\n=== 正在添加椒盐噪声 ===\n');

% 创建图像副本
noisy_image = original_image;

% 计算总像素数和噪声像素数
total_pixels = rows * cols;
num_noise_pixels = round(noise_density * total_pixels);
fprintf('总像素数: %d\n', total_pixels);
fprintf('噪声像素数: %d\n', num_noise_pixels);

% 生成随机噪声位置
rng('shuffle');  % 随机种子，确保每次运行结果不同
noise_indices = randperm(total_pixels, num_noise_pixels);

% 分割为盐噪声(白点)和椒噪声(黑点)
salt_count = floor(num_noise_pixels / 2);
pepper_count = num_noise_pixels - salt_count;

salt_indices = noise_indices(1:salt_count);
pepper_indices = noise_indices(salt_count+1:end);

fprintf('盐噪声点数: %d (白点)\n', salt_count);
fprintf('椒噪声点数: %d (黑点)\n', pepper_count);

% 添加噪声到每个通道
for ch = 1:channels
    channel_data = noisy_image(:,:,ch);
    
    % 添加盐噪声 (最大值，对于uint8为255)
    if isinteger(channel_data)
        channel_data(salt_indices) = intmax(class(channel_data));
    else
        channel_data(salt_indices) = 1.0;  % 对于double类型，最大值为1
    end
    
    % 添加椒噪声 (最小值，对于uint8为0)
    channel_data(pepper_indices) = 0;
    
    noisy_image(:,:,ch) = channel_data;
end

fprintf('椒盐噪声添加完成!\n');

%% 图像质量评估
fprintf('\n=== 图像质量评估 ===\n');

% 转换为double类型进行计算
original_double = double(original_image);
noisy_double = double(noisy_image);

% 计算均方误差 (MSE)
mse_value = mean((original_double(:) - noisy_double(:)).^2);
fprintf('均方误差 (MSE): %.4f\n', mse_value);

% 计算峰值信噪比 (PSNR)
if mse_value == 0
    psnr_value = Inf;
else
    max_pixel_value = double(intmax(class(original_image)));
    psnr_value = 20 * log10(max_pixel_value / sqrt(mse_value));
end
fprintf('峰值信噪比 (PSNR): %.2f dB\n', psnr_value);

% 计算信噪比 (SNR)
signal_power = mean(original_double(:).^2);
noise_power = mse_value;
if noise_power == 0
    snr_value = Inf;
else
    snr_value = 10 * log10(signal_power / noise_power);
end
fprintf('信噪比 (SNR): %.2f dB\n', snr_value);

% 计算结构相似性指数 (SSIM)
if channels == 1
    ssim_value = ssim(noisy_image, original_image);
else
    % 对于彩色图像，计算每个通道的SSIM并取平均
    ssim_r = ssim(noisy_image(:,:,1), original_image(:,:,1));
    ssim_g = ssim(noisy_image(:,:,2), original_image(:,:,2));
    ssim_b = ssim(noisy_image(:,:,3), original_image(:,:,3));
    ssim_value = (ssim_r + ssim_g + ssim_b) / 3;
end
fprintf('结构相似性指数 (SSIM): %.4f\n', ssim_value);

%% 结果显示
fprintf('\n=== 生成结果显示 ===\n');

% 创建主显示窗口
main_fig = figure('Name', '椒盐噪声处理结果', 'NumberTitle', 'off', ...
                 'Position', [100, 100, 1400, 600]);

% 显示原始图像
subplot(2, 3, 1);
imshow(original_image);
title('原始图像', 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示噪声图像
subplot(2, 3, 2);
imshow(noisy_image);
title(['添加椒盐噪声 (密度: ', num2str(noise_density*100), '%)'], ...
      'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示噪声分布图
subplot(2, 3, 3);
if channels == 1
    noise_map = abs(noisy_double - original_double);
else
    noise_map = sum(abs(noisy_double - original_double), 3) / channels;
end
noise_map_display = uint8(255 * noise_map / max(noise_map(:)));
imshow(noise_map_display);
colormap(jet);
colorbar;
title('噪声分布图', 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示局部放大对比
subplot(2, 3, 4);
% 选择图像中心区域进行放大显示
crop_size = min(rows, cols) / 4;
start_row = max(1, round(rows/2 - crop_size/2));
start_col = max(1, round(cols/2 - crop_size/2));
end_row = min(rows, start_row + crop_size - 1);
end_col = min(cols, start_col + crop_size - 1);

original_crop = original_image(start_row:end_row, start_col:end_col, :);
imshow(original_crop);
title('原始图像局部', 'FontSize', 12, 'FontWeight', 'bold');

subplot(2, 3, 5);
noisy_crop = noisy_image(start_row:end_row, start_col:end_col, :);
imshow(noisy_crop);
title('噪声图像局部', 'FontSize', 12, 'FontWeight', 'bold');

% 显示质量指标
subplot(2, 3, 6);
axis off;
text(0.1, 0.9, '图像质量指标:', 'FontSize', 14, 'FontWeight', 'bold');
text(0.1, 0.7, sprintf('MSE: %.4f', mse_value), 'FontSize', 12);
text(0.1, 0.6, sprintf('PSNR: %.2f dB', psnr_value), 'FontSize', 12);
text(0.1, 0.5, sprintf('SNR: %.2f dB', snr_value), 'FontSize', 12);
text(0.1, 0.4, sprintf('SSIM: %.4f', ssim_value), 'FontSize', 12);
text(0.1, 0.2, sprintf('噪声密度: %.1f%%', noise_density*100), 'FontSize', 12, 'Color', 'red');

%% 保存处理结果
fprintf('\n=== 保存处理结果 ===\n');

try
    % 保存噪声图像
    if contains(output_filename, '.jpg', 'IgnoreCase', true) || contains(output_filename, '.jpeg', 'IgnoreCase', true)
        imwrite(noisy_image, output_filename, 'Quality', output_quality);
    else
        imwrite(noisy_image, output_filename);
    end
    fprintf('噪声图像已保存: %s\n', output_filename);
    
    % 保存噪声分布图
    imwrite(noise_map_display, 'noise_distribution.png');
    fprintf('噪声分布图已保存: noise_distribution.png\n');
    
    % 保存质量报告
    report_filename = 'image_quality_report.txt';
    fid = fopen(report_filename, 'w');
    fprintf(fid, '椒盐噪声处理质量报告\n');
    fprintf(fid, '=====================\n\n');
    fprintf(fid, '处理时间: %s\n', datestr(now));
    fprintf(fid, '原始图像: %s\n', image_path);
    fprintf(fid, '图像尺寸: %d x %d x %d\n', rows, cols, channels);
    fprintf(fid, '噪声密度: %.1f%%\n', noise_density * 100);
    fprintf(fid, '\n质量指标:\n');
    fprintf(fid, '均方误差 (MSE): %.4f\n', mse_value);
    fprintf(fid, '峰值信噪比 (PSNR): %.2f dB\n', psnr_value);
    fprintf(fid, '信噪比 (SNR): %.2f dB\n', snr_value);
    fprintf(fid, '结构相似性指数 (SSIM): %.4f\n', ssim_value);
    fclose(fid);
    fprintf('质量报告已保存: %s\n', report_filename);
    
catch ME
    warning('文件保存失败: %s', ME.message);
end

%% 不同噪声密度对比（可选）
fprintf('\n=== 生成不同噪声密度对比图 ===\n');

compare_fig = figure('Name', '不同噪声密度对比', 'NumberTitle', 'off', ...
                    'Position', [150, 150, 1200, 800]);

noise_levels = [0.01, 0.03, 0.05, 0.1, 0.15, 0.2];
titles = {'1%噪声', '3%噪声', '5%噪声', '10%噪声', '15%噪声', '20%噪声'};

for i = 1:6
    % 为每个噪声级别创建噪声图像
    test_noisy = original_image;
    num_pixels = round(noise_levels(i) * total_pixels);
    noise_idx = randperm(total_pixels, num_pixels);
    
    salt_idx = noise_idx(1:floor(num_pixels/2));
    pepper_idx = noise_idx(floor(num_pixels/2)+1:end);
    
    for ch = 1:channels
        channel_data = test_noisy(:,:,ch);
        
        if isinteger(channel_data)
            channel_data(salt_idx) = intmax(class(channel_data));
        else
            channel_data(salt_idx) = 1.0;
        end
        
        channel_data(pepper_idx) = 0;
        test_noisy(:,:,ch) = channel_data;
    end
    
    subplot(2, 3, i);
    imshow(test_noisy);
    title(titles{i}, 'FontSize', 11, 'FontWeight', 'bold');
end

sgtitle('不同噪声密度效果对比', 'FontSize', 14, 'FontWeight', 'bold');

% 保存对比图
try
    saveas(compare_fig, 'noise_comparison.png');
    fprintf('噪声对比图已保存: noise_comparison.png\n');
catch
    warning('对比图保存失败');
end

%% 程序完成
fprintf('\n=== 程序执行完成 ===\n');
fprintf('所有处理结果已保存到当前目录\n');
fprintf('生成的文件:\n');
fprintf('  - %s (主要噪声图像)\n', output_filename);
fprintf('  - noise_distribution.png (噪声分布图)\n');
fprintf('  - noise_comparison.png (不同噪声密度对比)\n');
fprintf('  - image_quality_report.txt (质量报告)\n');

% 显示完成信息
msgbox({'程序执行完成!', ...
       sprintf('噪声图像已保存: %s', output_filename), ...
       sprintf('噪声密度: %.1f%%', noise_density*100), ...
       sprintf('PSNR: %.2f dB', psnr_value)}, ...
       '完成', 'help');