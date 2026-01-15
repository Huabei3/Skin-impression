function [area,points]=EllipsesIntersection(v1,v2)
%calculates intersection of two ellipses and gives area 
%and intersection circumference points
%ellipse format -->v=[Rmax,Rmin,xc,yc,theta]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
e1(1:2)=v1(3:4);e2(1:2)=v2(3:4);
cik1=v2cik(v1);cik2=v2cik(v2);
e1(3)=cik1(1,1);e1(4)=cik1(1,2);e1(5)=cik1(2,2);e2(3)=cik2(1,1);e2(4)=cik2(1,2);e2(5)=cik2(2,2);

    % Center of a coordinate system is moved to the center 
    % of the first ellipse 
    t_e2(1:2)=e2(1:2)-e1(1:2);
    t_e1(1:2)=e1(1:2)-e1(1:2);
    
    % Out of arguments we construct a matrix of coefficients
    M1=[e1(3) e1(4);e1(4) e1(5)];
    M2=[e2(3) e2(4);e2(4) e2(5)];

    % Eigenvectors and eigenvalues of the ellipses
    [vec1 val1]=eig(M1);
    [vec2 val2]=eig(M2);
    alpha1=atan2(vec1(4),vec1(3));
    
    % The second ellipse is rotated around the coordinate 
    % system center so that the first ellipse's semimajor
    % and semiminor axis are parallel to the coordinate 
    % system axes
    beta=alpha1-pi/2;
    R1=[cos(beta) sin(beta); -sin(beta) cos(beta)];  
    t2_e2=R1*t_e2(1:2)';    
    r_vec2=R1*vec2;
    MR2=r_vec2*val2*r_vec2';
        
    % The first ellipse is scaled to the unit circle and
    % the second ellipse is scaled accordingly
    t3_e2=sqrt(val1)*t2_e2;
    f=1/sqrt(val1(1)*val1(4));
    MR2_2=[MR2(1)/val1(1) MR2(3)*f;MR2(2)*f MR2(4)/val1(4)];

    % The second ellipse is rotated so that its axes are 
    % parallel to the coordinate system axes
    [vec3 val3]=eig(MR2_2);
    alpha2_2=atan2(vec3(4),vec3(3));
    gama=alpha2_2-pi/2;
    R3=[cos(gama) sin(gama); -sin(gama) cos(gama)];  
    MR2_3=R3*MR2_2*R3';
    t4_e2=R3*t3_e2;;
    
    % We calculate points of intersection between the second ellipse
    % and the unit circle
    points=unitCircleEllipseIntersection(MR2_3(1),MR2_3(4),t4_e2(1),t4_e2(2));
    % We calculate area of intersection between the second ellipse
    % and the unit circle
    area=unitCircleEllipseAreaOfIntersection(MR2_3(1),MR2_3(4),t4_e2(1),t4_e2(2),points);
    
    if area~=-1
        % We denormalize the area of intersection by multiplying it with the
        % first ellipse semimajor and semiminor axis.
        area=area/sqrt(val1(1)*val1(4));
    end
    
    % We denormalize the points of intersection
    if size(points,1)>0
        for i=1:size(points,1)
            point=R3'*points(i,:)';
            point(1)=point(1)/sqrt(val1(1));
            point(2)=point(2)/sqrt(val1(4));
            point=R1'*point;
            points(i,1)=point(1)+e1(1);
            points(i,2)=point(2)+e1(2);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function area=unitCircleEllipseAreaOfIntersection(A,C,u,v,points)

    % Constant specifying when the value is considered zero
    VALUE_EPS=1.0e-05;
    
    area=-1;
    
    if (A<0) | (C<0)
        error('A or C are negative.');
    end
    
    if (A<VALUE_EPS) | (C<VALUE_EPS)
        % Area is zero
        area=0;
        return
    end
    
    points_size=size(points,1);
    if mod(points_size,2)~=0
        %error(sprintf('There must be an even number of points.(A=%10.10f, C=%10.10f, u=%10.10f, v=%10.10f)',...
        %    A,C,u,v));                                     (Version 1.0)
        error(sprintf('There must be an even number of points.(A=%10.15f, C=%10.15f, u=%10.15f, v=%10.15f)',...
           A,C,u,v));                                     % (Version 1.1)
    end
    
    if points_size==0
        % The unit circle and the ellipse do not intersect. This lead to
        % two special cases.
        if (u^2+v^2)<1
            % The ellipse center is within the unit circle. The area of
            % intersection equals the area of the ellipse
            area=min(pi,pi/sqrt(A*C));
        elseif (A*u^2+C*v^2)<1
            % The unit circle center is withing the ellipse. The area of
            % intersection equals the area of the unit circle
            area=pi;
        end
    else
        % Calculation of points angles.
        points(:,3:4)=0;
        for i=1:points_size 
            % The ellipse is transformed to an unit circle too.
            points(i,3)=atan2(sqrt(C)*(points(i,2)-v),sqrt(A)*(points(i,1)-u));
            if points(i,3)<0
                points(i,3)=2*pi+points(i,3);
            end
            points(i,4)=atan2(points(i,2),points(i,1));
            if points(i,4)<0
                points(i,4)=2*pi+points(i,4);
            end
        end
        
        % Points are sorted by an angle
        points=sortrows(points,[3]);
        % Initial value. Just for the case of two double zeros.
        area=pi;
        for i=1:points_size
            if i==points_size
                next_idx=1;
            else
                next_idx=i+1;
            end
            if points(i,3)~=points(next_idx,3)
                % The consecutive points are not double zeros.
                mid_angle=mod(points(i,3)+subtractAngles(points(next_idx,3),points(i,3))/2,2*pi);
                x_mid=cos(mid_angle)/sqrt(A)+u;
                y_mid=sin(mid_angle)/sqrt(C)+v;
                
                if sqrt(x_mid^2+y_mid^2)<1
                    % The chord linking two consecutive points on the
                    % ellipse is within the unit circle
                    if points_size==2
                        % The case of two points intersection
                        
                        % Area between the chord and the ellipse
                        theta=subtractAngles(points(next_idx,3),points(i,3));
                        area=areaOfSector(theta)/sqrt(A*C);
                        
                        % Area between the chord and the unit circle
                        theta=subtractAngles(points(next_idx,4),points(i,4));
                        mid_angle=mod(points(i,4)+theta/2,2*pi);
                        x_mid=cos(mid_angle);
                        y_mid=sin(mid_angle);
                        if sqrt(A*(x_mid-u)^2+C*(y_mid-v)^2)>1
                            % Selected part of the unit circle is outside
                            % of the ellipse. We choose the other part.
                            theta=2*pi-theta;
                        end
                        % Area of intersection is a sum of the area between the
                        % chord and the ellipse and the area  between the
                        % chord and the unit circle
                        area=area+areaOfSector(theta);
                    elseif points_size==4
                        orig_i=i;
                        % In case of four points intersection is the next
                        % segment outside of the unit circle, so we skip
                        % these two points.
                        next_idx=next_idx+2;
                        if next_idx>points_size
                            next_idx=next_idx-points_size;
                        end
                        
                        theta=subtractAngles(points(next_idx,3),points(i,3));
                        if theta==0
                            % Double zero.
                            area=pi/sqrt(A*C);
                        else
                            % Area between the chord and the ellipse
                            area=areaOfSector(theta)/sqrt(A*C);
                            % Area between the chord and the unit circle
                            theta=subtractAngles(points(i,4),points(next_idx,4));
                            % Area of intersection is a sum of the area between the
                            % chord and the ellipse and the area  between the
                            % chord and the unit circle
                            area=area+theta/2-cos(theta/2)*sin(theta/2);
                        end
                        
                        % Now we subtract the next sector which lie outside
                        % of the unit circle.
                        neg_area=0;
                        i=i+1;
                        if i>points_size
                            i=i-points_size;
                        end
                        next_idx=i+1;
                        if next_idx>points_size
                            next_idx=next_idx-points_size;
                        end
                        if points(i,3)~=points(next_idx,3)
                            % Area between the chord and the ellipse
                            theta=subtractAngles(points(next_idx,3),points(i,3));
                            neg_area=areaOfSector(theta)/sqrt(A*C);
                            % Area between the chord and the unit circle
                            theta=subtractAngles(points(next_idx,4),points(i,4));
                            % Area of intersection is a sum of the area between the
                            % chord and the ellipse and the area  between the
                            % chord and the unit circle
                            neg_area=neg_area-(theta/2-cos(theta/2)*sin(theta/2));
                        end
                        area=area-neg_area;
                    else
                        error('Wrong number of points of intersection.');
                    end
                    
                    break;
                end
            end
        end
    end
end

function theta=subtractAngles(alpha,beta)
    if alpha<beta
        theta=2*pi+alpha-beta;
    else
        theta=alpha-beta;
    end
end

function area=areaOfSector(theta)
    if theta>=pi
        theta=2*pi-theta;
        area=pi-(theta/2-cos(theta/2)*sin(theta/2));
    else
        area=theta/2-cos(theta/2)*sin(theta/2);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% unitCircleEllipseIntersection 
%
% Computes points of intersection between
% an unit circle and an ellipse oriented along the coordinate axes.
%
% Usage:   points=unitCircleEllipseIntersection(A,C,u,v)
%
% Arguments:
%          A - 1/sqrt(a) where a is major axis along x coordinate
%          C - 1/sqrt(b) where b is major axis along y coordinate
%          u - x position of the second ellipse center
%          v - y position of the second ellipse center
%
% Returns:
%          points - a nx2 array of x and y coordinates of points of
%                   intersection. n is between 0 and 4.
%
% Author:
% Dušan Omerèeviæ
% Faculty of computer and information science
% University of Ljubljana
% http://vicos.fri.uni-lj.si/dusano/
%
% February 2006 - version 1.1
% November 2005 - version 1.0
%
% Math sources:
% http://mathforum.org/dr.math/faq/faq.cubic.equations.html
% http://mathworld.wolfram.com/QuadraticEquation.html
% http://mathworld.wolfram.com/CircularSegment.html
% http://www.math.niu.edu/~rusin/known-math/95/ellipse.int
%
% Routine uses cubic equation solver by Herman Bruyninckx.
% See cubic.m for further details.

function points=unitCircleEllipseIntersection(A,C,u,v)

    % Constant specifying when the imaginary part is considered zero
    % IMAG_EPS=1.0e-05;                                     (Version 1.0)
    IMAG_EPS=1.0e-02;                                     % (Version 1.1)
    % Constant specifying when the value is considered zero
    VALUE_EPS=1.0e-05;
    % Constant specifying when the u and/or v are considered zero
    UV_EPS=1.0e-02;
    
    if (A<0) | (C<0)
        error('A or C are negative.');
    end
    
    if (A<VALUE_EPS) || (C<VALUE_EPS)
        % The ellipse is degenerate.
        points=[];
        return
    end

    % Intermediate calculations
    R=A*u;
    Q=C*v;
    M=A-C;
    N=-1+C+A*u^2+C*v^2;
    MN=M*N;

    if abs(M)<VALUE_EPS
        % If the ellipse has A==C than the ellipse is a circle. This
        % requires a special case.
        D=-N^2*Q^2+4*Q^4+4*Q^2*R^2;
        F=2*(Q^2+R^2);
        if abs(F)<VALUE_EPS
            % The second ellipse/circle is at the origin. Either all or no
            % points intersect.
            points=[];
            return;
        end
        
        x(1)=(-sqrt(D)+N*R)/F;
        x(2)=(sqrt(D)+N*R)/F;
        
        % Intermediate calculations
        yD=(1-A*u^2+2*A*u*x-A*x.^2)/C;
    elseif (abs(u)<UV_EPS) & (abs(v)<UV_EPS)
        % Special case when u==0 and v==0)
        x(1)=-sqrt(1-C)/sqrt(A-C);
        x(2)=x(1);
        x(3)=-x(1);
        x(4)=x(3);
        
        % Intermediate calculations
        yD=(1-A*x.^2)/C;
    elseif abs(v)<UV_EPS
        % Special case when v==0)
        D=A-C-A*C+C^2+A*C*u^2;
        x(1)=(A*u-sqrt(D))/(A-C);
        x(2)=x(1);
        x(3)=(A*u+sqrt(D))/(A-C);
        x(4)=x(3);
        
        % Intermediate calculations
        yD=(1-A*u^2+2*A*u*x-A*x.^2)/C;
    elseif abs(u)<UV_EPS
        % Special case when u==0)
        N=-1+C+C*v^2;
        D=M*(M+N)+Q^2;

        x(1)=sqrt(-2*MN-4*sqrt(D)*Q-4*Q^2)/(sqrt(2)*M);
        x(2)=-x(1);
        x(3)=sqrt(-2*MN+4*sqrt(D)*Q-4*Q^2)/(sqrt(2)*M);
        x(4)=-x(3);
        
        % Intermediate calculations
        yD=(1-A*x.^2)/C;
    else       
        if abs(M)>1
            e=2*M*N+4*Q^2-2*R^2;
            f=8*Q^2*R;
            g=M^2*(N^2-4*Q^2)-2*M*N*R^2+4*Q^2*R^2+R^4;

            cubic_roots=cubic(1,2*e,e^2-4*g,-f^2);
            
            s_table=zeros(3,3);
            s_idx=0;
            if size(cubic_roots,1)>0
                for i=1:size(cubic_roots,1)
                    if (abs(imag(cubic_roots(i)))<IMAG_EPS) & (cubic_roots(i)>=0)
                        s_idx=s_idx+1;
                        s_table(s_idx,1)=real(cubic_roots(i));
                        s_table(s_idx,2)=abs(cubic_roots(i)^3+2*e*cubic_roots(i)^2+(e^2-4*g)*cubic_roots(i)-f^2);
                        s_table(s_idx,3)=s_table(s_idx,2)/s_table(s_idx,1);
                    end
                end
            end

            if s_idx>0
                s_table=sortrows(s_table([1:s_idx],:),[3]);
                s=s_table(1,1);
                h=sqrt(s);
                W1=sqrt(s-2*(e-f/h+s));
                W2=sqrt(s-(8*g)/(e-f/h+s));

                x(1)=((-h+W1)/2+R)/M;
                x(2)=((-h-W1)/2+R)/M;;
                x(3)=((h+W2)/2+R)/M;
                x(4)=((h-W2)/2+R)/M;

                % Intermediate calculations
                yD=(1-A*u^2+2*A*u*x-A*x.^2)/C;
            else
                x=[];
                yD=[];
            end
        else
            e=(2*N)/M+(4*Q^2-2*R^2)/M^2;
            f=(8*Q^2*R)/M^3;
            g=(N^2-4*Q^2)/M^2-(2*N*R^2)/M^3+(4*Q^2*R^2+R^4)/M^4;

            cubic_roots=cubic(1,2*e,e^2-4*g,-f^2);

            s_table=zeros(3,3);
            s_idx=0;
            if size(cubic_roots,1)>0
                for i=1:size(cubic_roots,1)
                    if (abs(imag(cubic_roots(i)))<IMAG_EPS) & (cubic_roots(i)>=0)
                        s_idx=s_idx+1;
                        s_table(s_idx,1)=real(cubic_roots(i));
                        s_table(s_idx,2)=abs(cubic_roots(i)^3+2*e*cubic_roots(i)^2+(e^2-4*g)*cubic_roots(i)-f^2);
                        s_table(s_idx,3)=s_table(s_idx,2)/s_table(s_idx,1);
                    end
                end
            end

            if s_idx>0
                s_table=sortrows(s_table([1:s_idx],:),[3]);
                s=s_table(1,1);
                h=sqrt(s);
                W1=sqrt(s-2*(e-f/h+s));
                W2=sqrt(s-(8*g)/(e-f/h+s));

                x(1)=(-h+W1)/2+R/M;
                x(2)=(-h-W1)/2+R/M;;
                x(3)=(h+W2)/2+R/M;
                x(4)=(h-W2)/2+R/M;

                % Intermediate calculations
                yD=(1-A*u^2+2*A*u*x-A*x.^2)/C;
            else
                x=[];
                yD=[];
            end
        end
    end     

    % Calculation of both possible y coordinates for all points.for
    %yD=sqrt(yD/(C^2));
    yD=sqrt(yD);
    y=v-yD;
    y2=v+yD;
    
    % Distance between the calculated points and unit circle. If close to
    % zero than we found an intersection between unit circle and the
    % ellipse
    e1=((x).^2+(y).^2-1).^2;
    e2=((x).^2+(y2).^2-1).^2;
    
    points_idx=0;
    points=zeros(4,2);
    i_size=size(x,2);    
    for i=1:i_size
        % Point is valid only if its imaginary part is considered zero.
        if (abs(imag(x(i)))<IMAG_EPS) & (abs(imag(y(i)))<IMAG_EPS)
            x_value=real(x(i));

            if ((e1(i)<=e2(i)) & (y(i)~=inf)) | (y2(i)==inf)
                y_value=real(y(i));
            else
                y_value=real(y2(i));
            end
            
            if (i<4)
                for j=i+1:i_size
                    if x_value==x(j)
                        if (y_value==y(j)) & (e2(j)<1/sqrt(C))
                            y(j)=inf;
                        elseif y_value==y2(j) & (e1(j)<1/sqrt(C))
                            y2(j)=inf;
                        end
                        break;
                    end
                end
            end
           
            points_idx=points_idx+1;
            points(points_idx,1)=x_value;
            points(points_idx,2)=y_value;
        end
    end
    
    if points_idx==0
        points=[];
    else
        points=points(1:points_idx,:);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [x] = cubic (a,b,c,d)

% [x] = cubic (a,b,c,d)
%
%   Gives the roots of the cubic equation
%         ax^3 + bx^2 + cx + d = 0    (a <> 0 !!)
%   by Nickalls's method: R. W. D. Nickalls, ``A New Approach to
%   solving the cubic: Cardan's solution revealed,''
%   The Mathematical Gazette, 77(480)354-359, 1993.
%   dicknickalls@compuserve.com

%  Herman Bruyninckx 10 DEC 1996, 19 MAY 1999
%  Herman.Bruyninckx@mech.kuleuven.ac.be 
%  Dept. Mechanical Eng., Div. PMA, Katholieke Universiteit Leuven, Belgium
%  <http://www.mech.kuleuven.ac.be/~bruyninc>
%
% THIS SOFTWARE COMES WITHOUT GUARANTEE.

if (abs(a)<eps) 
  printf('Coefficient of highest power must not be zero!\n'); 
  return; 
end;

x = NaN * ones(3,1);

xN = -b/3/a;
yN = d + xN * (c + xN * (b + a*xN));

two_a    = 2*a;
delta_sq = (b*b-3*a*c)/(9*a*a);
h_sq     = two_a * two_a * delta_sq^3;
dis      = yN*yN - h_sq;
pow      = 1/3;

if dis >= eps
  % one real root:
  dis_sqrt = sqrt(dis);
  r_p  = yN - dis_sqrt;
  r_q  = yN + dis_sqrt;
  p    = -sign(r_p) * ( sign(r_p)*r_p/two_a )^pow;
  q    = -sign(r_q) * ( sign(r_q)*r_q/two_a )^pow;
  x(1) = xN + p + q;
  x(2) = xN + p * exp(2*pi*i/3) + q * exp(-2*pi*i/3);
  x(3) = conj(x(2));
elseif dis < -eps
  % three distinct real roots:
  theta = acos(-yN/sqrt(h_sq))/3;
  delta = sqrt(delta_sq);
  two_d = 2*delta;
  twop3 = 2*pi/3;
  x     = [xN + two_d*cos(theta); ...
           xN + two_d*cos(twop3-theta); ...
           xN + two_d*cos(twop3+theta)];
else % abs(dis) <= -eps
  % three real roots (two or three equal):
  delta = (yN/two_a)^pow;
  x     = [xN + delta; xN + delta; xN - 2*delta];
end;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%