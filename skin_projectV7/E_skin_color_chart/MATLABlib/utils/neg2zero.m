function X=neg2zero(X)
X=(X+X.*sign(X))/2;
end