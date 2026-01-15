function XYZ=refl2xyz(refl,spddata,xyz,range) %载入反射率和光谱数据，反射率可以多列，但光源只能有一个 

    x=range;
    if(size(x,1)==1)
        x=x';%确保x是n*1的数列
    end
    
    %光源数据
    if (isstr(spddata))
        spddata=[spddata,'.mat'];
        load(spddata);
    end
    
   if(size(spddata,1)~=size(x,1))
        spddata=find_spd(spddata,x);  
   end
    
    %反射率内插
    if (size(refl,1)~=size(x,1))
        refl=find_spd(refl,x);
    end
     
    %xyz数据  请选择观察视角
    if(exist('xyz')~=1)
        xyzname=['cie',num2str(1964),'xyz'];
        load(xyzname)%间隔5的观测者 
    end
    
    if(size(xyz,1)~=size(x,1))
        xyz=find_spd(xyz,x);
    end
    
    xyz(:,1)=[];refl(:,1)=[];spddata(:,1)=[];
    temp=bsxfun(@times,spddata,xyz);%spd*xyz;列相乘;
    n=size(refl,2);
    X=sum(bsxfun(@times,temp(:,1),refl));
    Y=sum(bsxfun(@times,temp(:,2),refl));
    Z=sum(bsxfun(@times,temp(:,3),refl));
    XYZ=683*(x(2)-x(1))*[X;Y;Z];%每一列代表一个XYZ
    XYZ(XYZ<0)=0.01;    
end