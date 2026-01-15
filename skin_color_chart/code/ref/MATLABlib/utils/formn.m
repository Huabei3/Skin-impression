function x = formn(x,n)
%round to n decimals
x = round(x.*10^n)./10^n;
end