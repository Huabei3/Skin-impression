%script that calculates and displays colorimetric data associated with
%measured spectrum
%__________________________________________________________________________

global showcolorimetry hcolorimetry handlesCol


if showcolorimetry==1;
    figure(hcolorimetry)
    
    global CALSPD_ calref_ srgbPT
 
    
    cspacemax=1;
    offset_xyYuvY=0.35;
    
    
    %reference source XYZ:
    xyzw2=spd2xyz(calref_,2);uvYw2=xyz2uvY(xyzw2);
    xyzw10=spd2xyz(calref_,10);
       
    
    %calculate colorimetric data for table1
    absorrel=0;
    xyz2=spd2xyz(CALSPD_,2,absorrel);
    xyz10=spd2xyz(CALSPD_,10,absorrel);
    xyY2=xyz2xyY(xyz2);
    xyY10=xyz2xyY(xyz10);
    uvY2=xyz2uvY(xyz2);
    uvY10=xyz2uvY(xyz10);
    
if calcmetrics==1
    %chrom, LER, metrics
    LER2=LER_(CALSPD_,2);
    LER10=LER_(CALSPD_,10);
    lab2=xyz2lab(xyz2,xyzw2);lab10=xyz2lab(xyz10,xyzw10);
    [Ra,Ri]=CIECRI(CALSPD_);
    [T2,dc2]=CCTa(xyz2,2);[T10,dc10]=CCTa(xyz10,10);
    [nRa,nRi]=CRI2012(CALSPD_);
    [Qa,Qi,Qf,Qp,Qfi,Qpi]=CQSv9p0(CALSPD_);
    [Rm,Rmi]=MCRI(CALSPD_,0.9,0);
    Datatable1=[xyz2,NaN,xyz10;xyY2,NaN,xyY10;uvY2,NaN,uvY10;LER2 NaN NaN NaN LER10 NaN NaN;T2 NaN NaN NaN T10 NaN NaN;...
        dc2 NaN NaN NaN dc10 NaN NaN;NaN.*ones(1,7);...
        lab2 NaN lab10;NaN.*ones(1,7);Ra NaN NaN NaN NaN NaN NaN;...
        Qa Qf Qp NaN NaN NaN NaN;nRa NaN NaN NaN NaN NaN NaN;...
        Rm NaN NaN NaN NaN NaN NaN];
     figure(hcolorimetry);
     set(handlesCol.Colori_table1,'Data',Datatable1); 
     
     %find max size
     
     sizes=([size(Ri,1),size(Qi,1),size(Qfi,1),size(Qpi,1),size(nRi,1),size(Rmi,1)]);
     maxsize=max(sizes);
      
     DataTable2=[[Ri;NaN.*ones(maxsize-sizes(1),1)],[Qi;NaN.*ones(maxsize-sizes(2),1)],[Qfi;NaN.*ones(maxsize-sizes(3),1)],...
         [Qpi;NaN.*ones(maxsize-sizes(4),1)],[nRi;NaN.*ones(maxsize-sizes(5),1)],[Rmi;NaN.*ones(maxsize-sizes(6),1)]];
     set(handlesCol.Metric_table,'Data',DataTable2);
end
     
    
    %plot spectrum
    set(handlesCol.axes_spd_colori,'HandleVisibility','ON');axes(handlesCol.axes_spd_colori); 
    xlabel('wavelength (nm)','Color',[1,1,1]);
    plot(CALSPD_(:,1),CALSPD_(:,2),'b');
    set(handlesCol.axes_spd_colori, 'Color', 'None');
    
    wavs=CALSPD_(:,1);wavs=[round(min(wavs)/100)*100:100:round(max(wavs)/100)*100];
%     radiance=linspace(min((CALSPD_(:,2))).*1.1,max((CALSPD_(:,2))).*1.1,10)
%     set(handlesCol.axes_spd_colori,'Xtick',wavs,'Xticklabel',sprintf('%1.0f|',wavs),'Xcolor','w')
%     set(handlesCol.axes_spd_colori,'Ytick',radiance,'Yticklabel',sprintf('%5.2f|',radiance),'Ycolor','w')
%     axis([wavs(1),wavs(end),radiance(1),radiance(end)]);set(handlesCol.axes_spd_colori, 'Color', 'None');
%     
    spdvalues=CALSPD_(:,2);spdvalues=spdvalues(~isnan(spdvalues) & ~isinf(spdvalues));
    if size(spdvalues)>1;radiance=linspace(min(spdvalues).*0.9,max(spdvalues).*1.1,10);else;radiance=linspace(min([0,min(spdvalues)]),max([0,max(spdvalues)]),10);end 
    if isempty(spdvalues);radiance=[0,1];end
    set(handles.axes_spd,'Xtick',wavs,'Xticklabel',sprintf('%1.0f|',wavs),'Xcolor','w'),
    set(handles.axes_spd,'Ytick',radiance,'Yticklabel',sprintf('%5.2f|',radiance),'Ycolor','w')
    axis([wavs(1),wavs(end),radiance(1),radiance(end)])
    line([wavs(1);wavs(end)],[0;0],'Color',[1,1,1]);
    
    
    
    
    %plot chromaticity
     set(handlesCol.axes_backchrom,'HandleVisibility','ON');axes(handlesCol.axes_backchrom); set(gca, 'Ydir', 'normal');hold on;
     image(srgbPT./255);axis off; axis equal;%axis image
     size_srgbPT=size(srgbPT);
     
     zoomedrangeB=((size_srgbPT(1)-1).*[0,cspacemax-offset_xyYuvY,0,cspacemax-offset_xyYuvY]./cspacemax)+1;
     axis(zoomedrangeB);
     
     set(handlesCol.axes_chrom,'HandleVisibility','ON');axes(handlesCol.axes_chrom); 
     zoomedrange=[0,cspacemax-offset_xyYuvY,0,cspacemax-offset_xyYuvY]; 
     hold off;plot(0,0,'k.');hold on;plotwhite(2,'uvY');plotBBlocus(2,'uvY');plotDaylocus(2,'uvY');
     plot_2(uvYw2,'bo');plot_2(uvYw2,'b*');
     plot_2(uvY2,'ro');plot_2(uvY2,'r*');
     line([uvYw2(1);uvY2(1)],[uvYw2(2);uvY2(2)],'LineWidth',1.5);hold off;
     set(handlesCol.axes_chrom, 'Color', 'None');
     set(handlesCol.axes_chrom,'Xtick',(0:0.1:cspacemax),'Xticklabel',sprintf('%1.3f|',(0:0.1:cspacemax)),'Ytick',(0:0.1:cspacemax),'Yticklabel',sprintf('%1.3f|',(0:0.1:cspacemax)),'Xcolor','w','Ycolor','w')
     axis(zoomedrange);
     xlabel('CIE u''','Color',[1,1,1]);ylabel('CIE v''','Color',[1,1,1]);
    
     global handlesCol;guidata(hcolorimetry,handlesCol);
     
     %global STOPSTART_;if STOPSTART_==0;break;end
end