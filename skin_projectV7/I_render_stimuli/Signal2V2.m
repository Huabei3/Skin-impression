function V=Signal2V2(R)   
n = 4;
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
% n=4;
for i=1:1:s1
    for j=i:1:s1
        for k=j:1:s1
            for m=k:1:s1
                r=R(i,:).*R(j,:).*R(k,:).*R(m,:);
                V=[V;r];
            end
        end
    end
end
if(n==4)
    return
end
% n> = 5
for i=1:1:s1
    for j=i:1:s1
        for k=j:1:s1
            for m=k:1:s1
                for p=m:1:s1
                    r=R(i,:).*R(j,:).*R(k,:).*R(m,:).*R(p,:);
                    V=[V;r];
                end
            end
        end
    end
end
