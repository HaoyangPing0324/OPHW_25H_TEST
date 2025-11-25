% 文本文件转ASCII码转换程序
% 输入文件: txt.txt
% 输出文件: ascii.txt

fprintf('=== 文本文件转ASCII码转换程序 ===\n');

% 定义输入输出文件名
input_file = 'txt.txt';
output_file = 'ascii.txt';

% 检查输入文件是否存在
if ~exist(input_file, 'file')
    error('输入文件不存在: %s\n请确保文件 txt.txt 存在于当前目录', input_file);
end

fprintf('输入文件: %s\n', input_file);
fprintf('输出文件: %s\n', output_file);

% 以只读方式打开输入文件
fid_input = fopen(input_file, 'r');
if fid_input == -1
    error('无法打开输入文件: %s', input_file);
end

% 以写入方式打开输出文件
fid_output = fopen(output_file, 'w');
if fid_output == -1
    fclose(fid_input);
    error('无法创建输出文件: %s', output_file);
end

fprintf('开始转换...\n');
char_count = 0;

try
    % 逐字符读取文件
    while ~feof(fid_input)
        % 读取一个字符
        ch = fscanf(fid_input, '%c', 1);
        
        if ~isempty(ch)
            % 获取字符的ASCII码值
            ascii_value = double(ch);
            
            % 转换为十六进制格式，确保是2位
            hex_str = upper(dec2hex(ascii_value, 2));
            
            % 写入输出文件，格式为: 8'hXX
            fprintf(fid_output, '8''h%s\n', hex_str);
            
            % 显示转换信息（可选）
            if ascii_value >= 32 && ascii_value <= 126  % 可打印字符
                fprintf('字符 ''%s'' -> ASCII: %3d -> 8''h%s\n', ...
                        ch, ascii_value, hex_str);
            else  % 不可打印字符（如换行符、制表符等）
                switch ascii_value
                    case 10
                        fprintf('字符 ''\\n'' -> ASCII: %3d -> 8''h%s\n', ...
                                ascii_value, hex_str);
                    case 13
                        fprintf('字符 ''\\r'' -> ASCII: %3d -> 8''h%s\n', ...
                                ascii_value, hex_str);
                    case 9
                        fprintf('字符 ''\\t'' -> ASCII: %3d -> 8''h%s\n', ...
                                ascii_value, hex_str);
                    otherwise
                        fprintf('字符 [0x%s] -> ASCII: %3d -> 8''h%s\n', ...
                                hex_str, ascii_value, hex_str);
                end
            end
            
            char_count = char_count + 1;
        end
    end
    
    fprintf('\n转换完成！\n');
    fprintf('总共转换了 %d 个字符\n', char_count);
    fprintf('输出已保存到: %s\n', output_file);
    
catch ME
    % 错误处理
    fclose(fid_input);
    fclose(fid_output);
    error('转换过程中发生错误: %s', ME.message);
end

% 关闭文件
fclose(fid_input);
fclose(fid_output);

fprintf('\n=== 输出文件预览（前20行） ===\n');
% 显示输出文件的前20行内容
try
    fid_preview = fopen(output_file, 'r');
    if fid_preview ~= -1
        for i = 1:20
            line = fgetl(fid_preview);
            if ~ischar(line)
                break;
            end
            fprintf('%s\n', line);
        end
        fclose(fid_preview);
    end
catch
    fprintf('无法预览输出文件内容\n');
end

fprintf('\n程序执行完毕！\n');