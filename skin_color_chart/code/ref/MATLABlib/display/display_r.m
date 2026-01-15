function RGB=display_r(XYZ, gogpars) %XYZ:n by 3
        load(gogpars);
        XYZ_R=bsxfun(@minus,XYZ',black'); 
        L_RGB=real(inv(max_RGB)*XYZ_R);%scaled lightness for each channel
        rdata=gog_r(coef_r,L_RGB(1,:));%Scaled R data
        gdata=gog_r(coef_g,L_RGB(2,:));
        bdata=gog_r(coef_b,L_RGB(3,:));
        RGB=[rdata;gdata;bdata]';
        RGB=(RGB-real(RGB)==0).*RGB;
        RGB(RGB<0)=0;
        RGB(RGB>1)=1;
end