function Q=CQSv9p0_c2(spdi,n,thetas,rescalingparameters)
[Qa,Qf,Qp,Qg]=CQSv9p0_c(spdi,thetas,rescalingparameters);
switch n
    case 1
        Q=Qa;
    case 2
        Q=Qf;
    case 3
        Q=Qp;
    case 4
        Q=Qg;
end
        