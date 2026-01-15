function XYZ = cameramodel_poly(RGB,lux_level)

load Pmatrix.mat

RGB = RGB/65535;

V = PolynomialModel(RGB',Num);
XYZ = Pmatrix(:,:,lux_level)*V;XYZ = XYZ';

V0 = PolynomialModel([0;0;0],Num);
XYZ0 = Pmatrix(:,:,lux_level)*V0;XYZ0 = XYZ0';

XYZ = XYZ - XYZ0;
XYZ(XYZ<0) = 0.0001;

end