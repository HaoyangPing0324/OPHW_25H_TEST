clc;
clear all;
close all;

%% 读取图像文件 - 请替换为您自己的图像路径
input_image_path = 'img.png';  % 输入图像路径
output_image_path = 'motion_blur_gaussian_noise.png';  % 输出图像路径

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

%% 设置运动模糊参数
motion_length = 20;    % 运动模糊长度（像素）
motion_angle = 45;    % 运动角度（度）

%% 设置高斯噪声参数
mean_value = 0;       % 噪声均值
variance = 0.10;      % 噪声方差
noise_intensity = sqrt(variance);  % 标准差

fprintf('\n=== 运动模糊参数 ===\n');
fprintf('模糊长度: %d 像素\n', motion_length);
fprintf('运动角度: %d 度\n', motion_angle);

fprintf('\n=== 高斯噪声参数 ===\n');
fprintf('噪声均值: %.2f\n', mean_value);
fprintf('噪声方差: %.3f\n', variance);
fprintf('噪声强度(标准差): %.3f\n', noise_intensity);

%% 添加运动模糊
fprintf('\n=== 正在添加运动模糊 ===\n');

% 创建运动模糊滤波器
h_motion = fspecial('motion', motion_length, motion_angle);

% 应用运动模糊
motion_blurred_image = imfilter(original_image, h_motion, 'replicate', 'conv');
fprintf('运动模糊添加完成!\n');

%% 添加高斯噪声
fprintf('\n=== 正在添加高斯噪声 ===\n');

% 转换为double类型便于计算
noisy_image = im2double(motion_blurred_image);

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

% 计算结构相似性指数 (SSIM)
if channels == 1
    ssim_value = ssim(noisy_image, original_image);
else
    ssim_r = ssim(noisy_image(:,:,1), original_image(:,:,1));
    ssim_g = ssim(noisy_image(:,:,2), original_image(:,:,2));
    ssim_b = ssim(noisy_image(:,:,3), original_image(:,:,3));
    ssim_value = (ssim_r + ssim_g + ssim_b) / 3;
end
fprintf('结构相似性指数 (SSIM): %.4f\n', ssim_value);

%% 显示结果对比
figure('Name', '运动模糊+高斯噪声处理结果', 'NumberTitle', 'off', ...
       'Position', [100, 100, 1500, 500]);

% 显示原始图像
subplot(1, 4, 1);
imshow(original_image);
title('原始图像', 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示运动模糊图像
subplot(1, 4, 2);
imshow(motion_blurred_image);
title(['运动模糊图像'], 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示最终噪声图像
subplot(1, 4, 3);
imshow(noisy_image);
title(['运动模糊+高斯噪声'], 'FontSize', 12, 'FontWeight', 'bold');
axis image;

% 显示噪声分布
subplot(1, 4, 4);
if channels == 1
    noise_map = abs(noisy_double - original_double);
else
    noise_map = mean(abs(noisy_double - original_double), 3);
end
imshow(noise_map * 15);  % 放大显示噪声
title('噪声分布 (放大15倍)', 'FontSize', 12, 'FontWeight', 'bold');
axis image;
colormap(jet);
colorbar;

%% 保存处理后的图像
fprintf('\n=== 保存图像 ===\n');

try
    imwrite(noisy_image, output_image_path);
    fprintf('处理后的图像已保存: %s\n', output_image_path);
    
    % 保存运动模糊图像
    imwrite(motion_blurred_image, 'motion_blur_only.png');
    fprintf('纯运动模糊图像已保存: motion_blur_only.png\n');
    
    % 保存质量信息到文本文件
    info_filename = 'motion_blur_gaussian_info.txt';
    fid = fopen(info_filename, 'w');
    fprintf(fid, '运动模糊+高斯噪声处理信息\n');
    fprintf(fid, '==========================\n\n');
    fprintf(fid, '处理时间: %s\n', datestr(now));
    fprintf(fid, '输入文件: %s\n', input_image_path);
    fprintf(fid, '输出文件: %s\n', output_image_path);
    fprintf(fid, '图像尺寸: %d x %d x %d\n', rows, cols, channels);
    fprintf(fid, '\n运动模糊参数:\n');
    fprintf(fid, '模糊长度: %d 像素\n', motion_length);
    fprintf(fid, '运动角度: %d 度\n', motion_angle);
    fprintf(fid, '\n高斯噪声参数:\n');
    fprintf(fid, '噪声均值: %.2f\n', mean_value);
    fprintf(fid, '噪声方差: %.3f\n', variance);
    fprintf(fid, '\n质量指标:\n');
    fprintf(fid, '均方误差: %.6f\n', mse_value);
    fprintf(fid, '峰值信噪比: %.2f dB\n', psnr_value);
    fprintf(fid, '结构相似性指数: %.4f\n', ssim_value);
    fclose(fid);
    fprintf('处理信息已保存: %s\n', info_filename);
    
catch ME
    warning('文件保存失败: %s', ME.message);
end

%% 不同参数对比（可选）
fprintf('\n=== 生成不同参数对比图 ===\n');

% 测试不同运动模糊长度
motion_lengths = [5, 10, 15, 20];
motion_titles = {'长度=5', '长度=10', '长度=15', '长度=20'};

motion_fig = figure('Name', '不同运动模糊长度对比', 'NumberTitle', 'off', ...
                   'Position', [150, 150, 1200, 800]);

for i = 1:4
    % 创建不同长度的运动模糊
    h_motion_test = fspecial('motion', motion_lengths(i), motion_angle);
    motion_test_img = imfilter(original_image, h_motion_test, 'replicate', 'conv');
    
    % 添加相同的高斯噪声
    test_noisy = im2double(motion_test_img);
    for ch = 1:channels
        gaussian_noise = noise_intensity * randn(rows, cols) + mean_value;
        noisy_channel = test_noisy(:, :, ch) + gaussian_noise;
        noisy_channel = max(0, min(1, noisy_channel));
        test_noisy(:, :, ch) = noisy_channel;
    end
    
    subplot(2, 2, i);
    imshow(im2uint8(test_noisy));
    title([motion_titles{i}, '像素'], 'FontSize', 11, 'FontWeight', 'bold');
end

sgtitle('不同运动模糊长度效果对比', 'FontSize', 14, 'FontWeight', 'bold');

% 保存对比图
try
    saveas(motion_fig, 'motion_blur_comparison.png');
    fprintf('运动模糊对比图已保存: motion_blur_comparison.png\n');
catch
    warning('对比图保存失败');
end

fprintf('\n=== 程序执行完成 ===\n');
fprintf('生成的图像适合用于测试高斯滤波器的性能！\n');