function XYZ=display_f(RGB,savefile)
%         load('gog_pars.mat');
        load(savefile);
        rdata=RGB(:,1)';
        gdata=RGB(:,2)';
        bdata=RGB(:,3)';
        Lr=gog(coef_r,rdata);Lr(Lr<0)=0;
        Lg=gog(coef_g,gdata);Lg(Lg<0)=0;
        Lb=gog(coef_b,bdata);Lb(Lb<0)=0;
        XYZ=bsxfun(@plus,max_RGB*[Lr;Lg;Lb],black');
        XYZ=real(XYZ');
end

