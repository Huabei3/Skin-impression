function [rflrecovered,failedrfls,DE] = RFLrecoveryfromxyz(xyzt,Ill,cieobs,rflset,DEtol,optim,rflt)
% Recover spectral reflectance for xyzt based on set of spectral
% reflectances. 
%
% INPUT: 
%   xyzt: target xyz (relative)
%   Ill: illuminant
%   cieobs: CIE observer
%   rflset: set of spectral reflectances
%   DEtol: DE error tolerances for u'v' and Y(Ymax=100)
%   optim: 1 = optimize further from \-solution using fmincon, 0 = NOT
%   rflt: target rfl (only for plot comparisson)
%
% OUTPUT
%   rflrecovered: set of spectral reflectances the same size as xyzt
%   failedrfls: array of 0/1, 0: rfl recovery failed witin DEtol, 1: recovery succesful
%
% Method according to:
% Kim, BG , Werner, JS , Siminovitch, M , Papamichael, K , Han, J , Park, S 
% Spectral Reflectivity Recovery from Tristimulus Values Using 
% 3D Extrapolation with 3D Interpolation. 
% Journal of the Optical Society of Korea [Internet]. 2014. Oct ; 5 (5) 
% Available from http://dx.doi.org/10.3807/JOSK.2014.18.5.507

if nargin < 5;DEtol=[0.003,1];end %DE error tolerances for u'v' and Y(Ymax=100)
if nargin < 6;optim = 0;end % 1: optimize further from \-solution using fmincon
if nargin < 7;rflt = [];end %target rfl (only for plot comparisson)

%verbosity: plot intermediate results during optimzation or not
verbosity = 1;

%initialize array
rflrecovered=nan(size(rflset,1),1);

%target u'v' chrom
uvYt = xyz2uvY(xyzt);

%set u'v' chrom
xyz = spd2xyz(Ill,cieobs,0,rflset);
uvY = xyz2uvY(xyz);

    
% Find 4 enclosing vertices using 
% Delaunay triangulation, the
% barycentric coordinates of the target points 
% and the circumcenters of the tetrahedrons
DT = DelaunayTri(xyz);
[tetids, bcs] = pointLocation(DT, xyzt);% tetrahedron # + barycentric coordinates (for use in 3D interpolation)
CC = circumcenters(DT); % circumcenters of all tetrahedrons (for use in 3D extrapolation)


% if xyzt inhull --> 3D interpolation:

    %get vertices of the tetrahedrons &  the barycentric co for inhull xyzt
    inhull_targets = ~isnan(tetids);
    vertices_in = DT.Triangulation(tetids(inhull_targets),:);
    bcs_in = bcs(inhull_targets,:);
    
    %calculate weighted average spectral reflectance (weights are barycentric coordinates)
    t=0;
    for i=1:size(xyzt,1)
        if inhull_targets(i)==1
            t = t + 1;
            rflrecovered(:,i) = sum(rflset(:,1+vertices_in(t,:)).*repmat(bcs_in(t,:),size(rflset,1),1),2);
        else
            rflrecovered(:,i) = nan(size(rflset,1),1);
        end
    end
    rflrecovered = [rflset(:,1),rflrecovered];
    rflrecoveredcpy = rflrecovered;
    
    %plot recovered rfl and 4 basis rfls. Also plot target rfl when given.
    if size(rflrecovered,2)==2;
        figure,
        hold on;
        plot(rflset(:,1),rflset(:,1+vertices_in(1)),'r--')
        plot(rflset(:,1),rflset(:,1+vertices_in(2)),'g--')
        plot(rflset(:,1),rflset(:,1+vertices_in(3)),'b--')
        plot(rflset(:,1),rflset(:,1+vertices_in(4)),'y--')
        plot(rflset(:,1),rflrecovered(:,2),'k-')
        if ~isempty(rflt);plot(rflset(:,1),rflt,'m'),end
    end
    
        
    %DE with target
    DEuvY = @(x1,x2) [sqrt((x1(:,1)-x2(:,1)).^2+(x1(:,2)-x2(:,2)).^2),sqrt((x1(:,3)-x2(:,3)).^2)];
    f = @(x) sqrt(x(:,1).^2+x(:,2).^2);
    warning off
    xyzrecovered = spd2xyz(Ill,cieobs,0,rflrecovered);
    uvYrecovered = xyz2uvY(xyzrecovered);
    DE = DEuvY(uvYrecovered,uvYt);
    disp(sprintf('3D interpolation: maxDE = [%1.4f %1.4f]',max(DE)))
    
%     figure(1),plotwhite(cieobs,'uvY');
%     plot_3(uvYt,'go');
%     plot_3(uvYrecovered,'k*');
%     plot_3(uvYrecovered(DE(:,1)>DEtol(1) | DE(:,2)>DEtol(2),:),'rs');
    
 

% if xyzt ~inhull --> 3D extrapolation

    %get distances between xyzt & tetrahedron circumcenters CC
    DEfcn = @(x1,x2) sqrt((x1(1)-x2(:,1)).^2+(x1(2)-x2(:,2)).^2+(x1(3)-x2(:,3)).^2);
    for i = 1:size(xyzt,1)
        if inhull_targets(i)==0 | DE(i,1)>DEtol(1) | DE(i,2)>DEtol(2) ;
            deCC(:,i) = DEfcn(xyzt(i,:),CC);
            pminCC(i) = find(deCC(:,i) == min(deCC(:,i)),1,'first');%position of CC wirh minimum distance
            vertices_out = DT.Triangulation(pminCC(i),:);
        
%             figure(1);
%             plot_3(xyz2uvY(xyz),'y.');
%             plot_3(xyz2uvY(xyz(vertices_out,:)),'g+');
%             plot_3(xyz2uvY(CC(pminCC(i),:)),'mx')
            
                   
            % calculate weigthing factors using \-operator (first guess for fmincon)
            d_out = ([xyz(vertices_out,:)';ones(1,4)]\[xyzt(i,:),1]')';
           
            %create rfli
            rfli = rflset(:,1+vertices_out)*d_out';
            rfli = [rflset(:,1),rfli];
            
            %calculate DE for rfl
            xyzrecoveredi = spd2xyz(Ill,cieobs,0,rfli);
            uvYrecoveredi = xyz2uvY(xyzrecoveredi);
            DEi = DEuvY(uvYrecoveredi,uvYt(i,:));
            
            if optim==1  %optimize further:          
                %optimize using fminsearch/fmincon
                %opts=optimset('fminsearch');x0=d_out;
                %d_out = fminsearch(@(d_out) optimfcn(d_out,xyzt(i,:),cieobs,Ill,vertices_out,rflset,DEuvY,f),x0,opts);

                %set up optim parameters
                opts = optimset('fmincon');
                x0=d_out';%set initial guess x0 as column vector

                %set up constraints such that RFL<=1 & RFL>=0
                A = rflset(:,1+vertices_out);
                A = [A;-A];
                B = [ones(size(rflset,1),1);zeros(size(rflset,1),1)];

                %set up constraints such that sum(d_out) = 1 
                Aeq = ones(1,4);
                Beq = 1;

                %find optimum weigths given the constraints
                d_out = fmincon(@(d_out) optimfcn(d_out,xyzt(i,:),cieobs,Ill,vertices_out,rflset,DEuvY,f,verbosity),x0,A,B,Aeq,Beq,[],[],[],opts);
                [DE_d_out,DE_d_out_1,DE_d_out_2] = optimfcn(d_out,xyzt(i,:),cieobs,Ill,vertices_out,rflset,DEuvY,f,verbosity);
                d_out=d_out';%make row vector

                disp(sprintf('sample # %1.0f, 3D interpolation                   : DE = %1.5f, DEuv = %1.5f, DEY = %1.3f',i,f(DE(i,1:2)),DE(i,1),DE(i,2)))
                disp(sprintf('sample # %1.0f, 3D extrapolation backslash-operator: DE = %1.5f, DEuv = %1.5f, DEY = %1.3f',i,f(DEi(1:2)),DEi(1),DEi(2)))
                disp(sprintf('sample # %1.0f, 3D extrapolation fmincon           : DE = %1.5f, DEuv = %1.5f, DEY = %1.3f',i,DE_d_out,DE_d_out_1,DE_d_out_2))
            
            
                %check if fmincon is better than \-operator
                if f(DEi)<=DE_d_out
                    disp(sprintf('backslash-operator solution better, keeping first guess.'))
                    d_out = x0';
                end
            
            
            end
            
            %calculate weighted average spectral reflectance from weigths
            %and basis rfls
            rflrecovered(:,i+1) = rflset(:,1+vertices_out)*d_out';
            rflrecovered(rflrecovered(:,i+1)<0,i+1)=0;
            rflrecovered(rflrecovered(:,i+1)>1,i+1)=1;
            
            %calculate DE for rfl
            xyzrecoveredi = spd2xyz(Ill,cieobs,0,[rflrecovered(:,1),rflrecovered(:,i+1)]);
            uvYrecoveredi = xyz2uvY(xyzrecoveredi);
       
            DEi_final = DEuvY(uvYrecoveredi,uvYt(i,:));
            
            
            %replace rfl with previously calculated when worse
            %[i,DE(i,:),DEi,f(DE(i,:)),f(DEi)]
            if ~isempty(DE(i))
                if f(DE(i,:))<f(DEi)
                    disp(sprintf('3D intrapolation DE smaller, replacing 3D interpolation result'));
                    rflrecovered(:,i+1) = rflrecoveredcpy(:,i+1);
                end
            end
            
            %plot recovered rfl and 4 basis rfls. Also plot target rfl when given.
             if size(rflrecovered,2)==2;
                figure,
                hold on;
                plot(rflset(:,1),rflset(:,1+vertices_out(1)),'r--')
                plot(rflset(:,1),rflset(:,1+vertices_out(2)),'g--')
                plot(rflset(:,1),rflset(:,1+vertices_out(3)),'b--')
                plot(rflset(:,1),rflset(:,1+vertices_out(4)),'y--')
                plot(rflset(:,1),rflrecovered(:,i+1),'k-')
                if ~isempty(rflt);plot(rflset(:,1),rflt,'m'),end
            end
        end
    end
    
    %DE with target
    DEuvY = @(x1,x2) [sqrt((x1(:,1)-x2(:,1)).^2+(x1(:,2)-x2(:,2)).^2),sqrt((x1(:,3)-x2(:,3)).^2)];
    xyzrecovered = spd2xyz(Ill,cieobs,0,rflrecovered);
    uvYrecovered = xyz2uvY(xyzrecovered);
       
    DE = DEuvY(uvYrecovered,uvYt);
    disp(sprintf('3D extrapolation: maxDE = [%1.4f %1.4f]',max(DE)))
    
    figure(1),plotwhite(cieobs,'uvY');
    plot_3(uvYt,'go');
    plot_3(uvYrecovered,'k*');
    plot_3(uvYrecovered(DE(:,1)>DEtol(1) | DE(:,2)>DEtol(2),:),'rs');
    
    %set rfls to NaN when there DE > DEtol
    failedrfls = (DE(:,1)>DEtol(1) | DE(:,2)>DEtol(2));
%     rflrecovered(:,find(failedrfls)+1)=NaN;
    
    %report total rfls succesfully generated
    disp(sprintf('Out of %1.0f requested targets %1.0f number of spectral reflectance functions were generated',size(xyzt,1),sum(DE(:,1)<=DEtol(1) & DE(:,2)<=DEtol(2))))
    
    
end


function [F,DE_d_out_1,DE_d_out_2] = optimfcn(d_out,xyzti,cieobs,Ill,vertices_out,rflset,DEuvY,f,verbosity)
%d_out = d_out';rfli = sum(rflset(:,1+vertices_out).*repmat(d_out,size(rflset,1),1),2);

%create rfl
rfli = rflset(:,1+vertices_out)*d_out;
rfli = [rflset(:,1),rfli];

%calculate u'v'Y chrom
uvYti = xyz2uvY(xyzti);
uvYrecoveredi = xyz2uvY(spd2xyz(Ill,cieobs,0,rfli));

%calculate DEuv and DEY and finally DE = sqrt(DEuv.^2+DEY.^2)
F = (DEuvY(xyz2uvY(xyzti),xyz2uvY(spd2xyz(Ill,cieobs,0,rfli))));
DE_d_out_1 = F(1);
DE_d_out_2 = F(2);
F = f(F);

%plot intermediate results
if verbosity == 1;
    figure(33);
    subplot(1,2,1);
    plot_2(rfli,'b');
    ylim([0 1])
    xlabel('wavelengths (nm)');ylabel('Spectral reflectance')
    subplot(1,2,2);
    plot_3(uvYti,'ro');
    hold on;
    plot_3(uvYrecoveredi,'b*');
    plotwhite(cieobs,'uvY');
    hold off;
    legend(gca,{'target','recovered'})
    xlabel('u''');ylabel('v''');zlabel('Y rel.')
    title(sprintf('DE = %1.5f, DEuv = %1.5f, DEY = %1.3f',F,DE_d_out_1,DE_d_out_2))
end
end