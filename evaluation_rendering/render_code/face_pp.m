% Face++ API 配置
apiKey = 'FvyCp6xuw4h1xvsPquJDG8rFfVYZV9z_';
apiSecret = 'AUadn4V7pEqVM6mbGd52xvoZJCku--VB';
url = 'https://api-cn.faceplusplus.com/facepp/v3/detect';

% 读取图片并进行 Base64 编码
imagePath = 'indoor01_downsampled.JPG';
[fid, err] = fopen(imagePath, 'rb');
if fid == -1
    error('无法打开图片文件: %s', err);
end
imageData = fread(fid, inf, 'uint8');
fclose(fid);
base64Image = matlab.net.base64encode(imageData);

% 手动拼接参数（避免格式问题）
postData = sprintf('api_key=%s&api_secret=%s&image_base64=%s&return_attributes=gender', ...
    urlencode(apiKey), ...       % 对 apiKey 进行 URL 编码
    urlencode(apiSecret), ...    % 对 apiSecret 进行 URL 编码
    urlencode(base64Image));     % 对 Base64 图片数据进行 URL 编码

% 配置请求选项
options = weboptions('RequestMethod', 'post', ...
    'HeaderFields', {'Content-Type', 'application/x-www-form-urlencoded'}, ...
    'Timeout', 30);

% 发送请求（将数据作为第二个参数传递）
try
    % 对于不支持Body参数的MATLAB版本，将数据作为第二个参数传递
    response = webwrite(url, postData, options);
    
    % 解析返回结果
    result = jsondecode(response);
    
    % 提取属性信息
    if isfield(result, 'faces') && ~isempty(result.faces)
        genderInfo = result.faces(1).attributes.gender;
        disp('性别识别结果:');
        disp(genderInfo);
    else
        disp('未检测到人脸');
    end
catch e
    disp('请求失败:');
    if isfield(e, 'response')
        disp('服务器响应:');
        disp(e.response);
    end
    disp('错误消息:');
    disp(e.message);
end
