function RGB=display_gam_r(XYZ, gampars) %XYZ:n by 3
        load(gampars);
        XYZ_R=XYZ'
        L_RGB=real(inv(max_RGB)*XYZ_R);%scaled lightness for each channel
        rdata=gam_r(gamma_r,L_RGB(1,:));%Scaled R data
        gdata=gam_r(gamma_g,L_RGB(2,:));
        bdata=gam_r(gamma_b,L_RGB(3,:));
        RGB=[rdata;gdata;bdata]';
        RGB=(RGB-real(RGB)==0).*RGB;
        RGB(RGB<0)=0;
        RGB(RGB>1)=1;
end