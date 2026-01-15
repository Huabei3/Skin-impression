function d = mahalanobis(data,a);
x = data(:,1);
y = data(:,2);
switch size(a,2)
    case 5;%2D ellipse
        d = sqrt(a(1).*(x-a(3)).^2 + a(2).*(y-a(4)).^2 + 2.*a(5).*(x-a(3)).*(y-a(4)));
    case 9
        z = data(:,3);
        d = sqrt(a(1).*(x-a(4)).^2 + a(2).*(y-a(5)).^2 + a(3).*(z-a(6)).^2 + 2.*a(7).*(x-a(4)).*(y-a(5)) + 2.*a(8).*(x-a(4)).*(z-a(6)) + 2.*a(9).*(y-a(5)).*(z-a(6)));
end

end