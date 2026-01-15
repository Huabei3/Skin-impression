function XYZ=display_gam_f(RGB, gampars)
        load(gampars);
        rdata=RGB(:,1)';
        gdata=RGB(:,2)';
        bdata=RGB(:,3)';
        Lr=gam(gamma_r,rdata);Lr(Lr<0)=0;
        Lg=gam(gamma_g,gdata);Lg(Lg<0)=0;
        Lb=gam(gamma_b,bdata);Lb(Lb<0)=0;
        XYZ=max_RGB*[Lr;Lg;Lb];
        XYZ=real(XYZ');
end

