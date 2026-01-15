function[lab,xyz,center,bull,count,round]=mask(img,startcenter,white,w,string)
    switch string
        case 'srgb'
            matrix=1;
        case 'polynomial'
            matrix=2;
        case 'LUT'
            matrix=3;
    end

    m=size(img);
    rgb=reshape(img,[m(1)*m(2),m(3)]);%横着压成一维%转成RGB
    bull0=zeros(size(rgb));
    
    if matrix==1
        xyz0=srgb2xyz(rgb);%转成xyz0（参考白）
        k=1;
    end
    if matrix==2
        xyz1=srgb2xyz(rgb);
        xyz0=rgb2xyz(rgb,w);
        k=y/y1;
    end
    if matrix==3
        datai_file = 'Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\datai_sorted40_3.mat';
        LUTdata=load(datai_file);
        rgb = rgb * 255;
        xyz0 = lut3d_rgb2xyz1(rgb, datai_file);
        white=LUTdata.XYZw;
        k=1;
%         k=100/XYZw(1,2);
    end
    lab0=xyz2lab(xyz0,'user',white*k);%转成lab0（参考白）（由xyz0和white）
    
    L0=startcenter(1);
    a0=startcenter(2);
    b0=startcenter(3);
    k1=startcenter(4);
    k2=startcenter(5);
    k3=startcenter(6);
    k4=startcenter(7);
    alpha=startcenter(8);%赋值 中国人【椭球】
    E=0.5;%控制肤色mask的准确度
   
    
    avl=0;
    round=0;
    while(abs(L0-avl)/L0>0.0001)%（平均亮度-椭球中心亮度）/椭球中心亮度 小于0.0001时停止
        count=0;
        suml=0;
        suma=0;
        sumb=0;
        for i=1:m(1)*m(2)
            l=lab0(i,1);
            a=lab0(i,2);
            b=lab0(i,3);%从原图和参考白得来的lab
            d=(k1*(l-L0)^2+k2*(a-a0)^2+k3*(b-b0)^2+k4*(a-a0)*(b-b0))^0.5;%原图的各处与椭圆色中心
            p=(1+exp(d-alpha))^(-1);%可感知喜好度
            if p>E
                bull0(i,:)=[1,1,1];%设为可信
                count=count+1;%计算可信的个数
                suml=suml+l;
                suma=suma+a;
                sumb=sumb+b;%计算所有可信的lab的和
                
            end
        end
        avl=L0;
        L0=suml/count;
        a0=suma/count;
        b0=sumb/count;%更新椭圆中心为可信的平均值
        round=round+1;
    end
    lab=reshape(lab0,m);%根本没有更新
    xyz=reshape(xyz0,m);%根本没有更新
    bull=reshape(bull0,m);
    center=[L0,a0,b0];   %得到肤色区域bull，以及平均肤色中心center，迭代轮次round
end