function [XYZ,linrgb] = raw2xyz(fileName)

cfaImage = rawread(fileName);
cfaInfo = rawinfo(fileName);
colorInfo = cfaInfo.ColorInfo;

% 黑电平
blackLevel = colorInfo.BlackLevel;
blackLevel = reshape(blackLevel,[1 1 numel(blackLevel)]);
blackLevel = planar2raw(blackLevel);
repeatDims = cfaInfo.ImageSizeInfo.VisibleImageSize ./ size(blackLevel);
blackLevel = repmat(blackLevel,repeatDims);
cfaImage = cfaImage - blackLevel;
cfaImage = max(0,cfaImage);

% 归一化
% whiteLevel = colorInfo.WhiteLevel;
% whiteLevel = reshape(whiteLevel,[1 1 numel(whiteLevel)]);
% whiteLevel = planar2raw(whiteLevel);
% repeatDims = cfaInfo.ImageSizeInfo.VisibleImageSize ./ size(whiteLevel);
% whiteLevel = repmat(whiteLevel,repeatDims);
% cfaImage = double(cfaImage);
% cfaImage = cfaImage ./ double(whiteLevel);

cfaImage = double(cfaImage);
maxValue = max(cfaImage(:));
cfaImage = cfaImage ./ maxValue;

% 白平衡
% whiteBalance = colorInfo.CameraAsTakenWhiteBalance;
whiteBalance = colorInfo.D65WhiteBalance;
disp("D65WhiteBalance");
gLoc = strfind(cfaInfo.CFALayout,"G");
gLoc = gLoc(1);
whiteBalance = whiteBalance/whiteBalance(gLoc);
whiteBalance = reshape(whiteBalance,[1 1 numel(whiteBalance)]);
whiteBalance = planar2raw(whiteBalance);
whiteBalance = repmat(whiteBalance,repeatDims);
cfaWB = cfaImage .* whiteBalance;
cfaWB = im2uint16(cfaWB);


% 去马赛克
cfaLayout = cfaInfo.CFALayout;
imDebayered = demosaic(cfaWB,cfaLayout);
imDebayered = imresize(imDebayered,0.25,"nearest");
linrgb = imDebayered;

%%
cam2xyzMat = colorInfo.CameraToXYZ;
whiteBalanceD65 = colorInfo.D65WhiteBalance;
cfaLayout = cfaInfo.CFALayout;
wbIdx(1) = strfind(cfaLayout,"R");
gidx = strfind(cfaLayout,"G");
wbIdx(2) = gidx(1);
wbIdx(3) = strfind(cfaLayout,"B");
wbCoeffs = whiteBalanceD65(wbIdx);
cam2xyzMat = cam2xyzMat ./ wbCoeffs;
XYZ = imapplymatrix(cam2xyzMat,im2double(imDebayered));

end