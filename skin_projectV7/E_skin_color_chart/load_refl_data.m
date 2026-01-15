addpath G:\20220613\data
load D65.mat;
D65=find_spd(D65,range);
load A.mat;
A=find_spd(A,range);
load F11.mat;
F11=find_spd(F11,range);
spdDE={D65,A,F11};

load("D50.mat");
D50=find_spd(D50,range);

load Rmccc.mat
refl1=find_spd(Rmccc,range);
load Rsg.mat
refl2=find_spd(Rsg,range);
load Rdigieye.mat
refl3=find_spd(Rdigieye,range);
load Rpmcc30.mat;
refl4=find_spd(Rpmcc,range);


load SFU_reflectance_db.mat;
reflSFU=find_spd([(380:4:780)',reflectance_SFU],range);  % 1995 SFU
