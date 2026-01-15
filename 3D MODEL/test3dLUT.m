clear;

lut = ThreeDLut(9, ['Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\' ...
    'test-color-patch-3-729.csv']);
lut = lut.load_lut();
lut = lut.generate_rgb_plab();

load("RGB.mat");

RGB=RGB*255;
XYZ_pre = lut3d_rgb2xyz1(RGB,datai_file);