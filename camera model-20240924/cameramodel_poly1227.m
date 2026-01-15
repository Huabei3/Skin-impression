function XYZ = cameramodel_poly1227(RGB)

load PmatrixD651227.mat
% load Pmatrix_raw_hdrD65.mat

RGB = RGB/65535;

V = PolynomialModel(RGB',Num);
XYZ = Pmatrix*V;XYZ = XYZ';

V0 = PolynomialModel([0;0;0],Num);
XYZ0 = Pmatrix*V0;XYZ0 = XYZ0';

XYZ = XYZ - XYZ0;
XYZ(XYZ<0) = 0.0001;

end