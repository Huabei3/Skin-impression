%output:3*3
function V=PolynomialModel(R,Num)

switch Num
    case 3
        n=0;
        V=R;
        if(n==0)
            return
        end
    case 11
        n=2;
        V=R;
        if(n==0)
            return
        end
        %n=1;
        [s1,s2]=size(R);
        one=ones(1,s2);
        V=[one;V];
        if(n==1)
            return
        end
        % n=2;
        for i=1:1:s1
            for j=i:1:s1
                r=R(i,:).*R(j,:);
                V=[V;r];
            end
        end
        r=R(1,:).*R(2,:).*R(3,:);
        V=[V;r];
        if(n==2)
            return
        end
    case 20
        n=3;
        V=R;
        if(n==0)
            return
        end
        %n=1;
        [s1,s2]=size(R);
        one=ones(1,s2);
        V=[one;V];
        if(n==1)
            return
        end
        % n=2;
        for i=1:1:s1
            for j=i:1:s1
                r=R(i,:).*R(j,:);
                V=[V;r];
            end
        end
        if(n==2)
            return
        end
        % n=3;
        for i=1:1:s1
            for j=i:1:s1
                for k=j:1:s1
                    r=R(i,:).*R(j,:).*R(k,:);
                    V=[V;r];
                end
            end
        end
        if(n==3)
            return
        end
end







