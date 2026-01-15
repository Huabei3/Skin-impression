%modeldarkmeasurement
measok=1;
switch measok
    case 1
     clear spds spd_ Tcounts ts spds_ Tcounts_ ts_
    spd_=getOOspdf(1,1,[0.008,1]);%koeling aan
    ts=[0.008.*(1:10),0.1:0.1:1,2:5,10,20,40:20:60];%integratietijden
    wr=spd_(:,1)>=359 & spd_(:,1)<=831;
    wr=1:size(spd_,1)-1;
    spds(:,1)=spd_(wr,1);
    cmap=colormap;
    cmap=cmap(1:floor(size(cmap,1)./numel(ts)):end,:);
    figure(1);
    for i=1:numel(ts)
        spd_ = getOOspdf(1,1,[ts(i),1]);
        spd_(:,2)=spd_(:,2).*ts(i);%van counts/s --> counts
        Tcounts(i)=sum(spd_(wr,2));
        spds(:,i+1)=spd_(wr,2)./Tcounts(i);
        subplot(1,3,1);hold on;plot(ts(i),Tcounts(i),'Color',cmap(i,:),'linestyle','none','marker','o');
        subplot(1,3,3);hold on;plot(spds(:,1),spds(:,i+1),'Color',cmap(i,:))
        subplot(1,3,2);hold on;plot(spd_(wr,1),spds(:,i+1).*Tcounts(i),'Color',cmap(i,:))

%         subplot(1,3,1);hold on;plot(ts(i),Tcounts(i),'Color',cmap(i,:),'linestyle','none','marker','o');
%         subplot(1,3,2);hold on;plot(spd_(wr,1),spd_(wr,2),'Color',cmap(i,:))
%         subplot(1,3,3);hold on;plot(spd_(wr,1),spd_(wr,2)./Tcounts(i),'Color',cmap(i,:))
    end
    case 0
        figure(1);
        for i=1:numel(ts)
            subplot(1,3,1);hold on;plot(ts(i),Tcounts(i),'Color',cmap(i,:),'linestyle','none','marker','o');
            subplot(1,3,3);hold on;plot(spds(:,1),spds(:,i+1),'Color',cmap(i,:))
            subplot(1,3,2);hold on;plot(spds(:,1),spds(:,i+1).*Tcounts(i),'Color',cmap(i,:))
        end
end

figure(3);hold on
plot(ts,Tcounts,'b.-')


mint=min(ts);
mint=2;
ts_=ts(ts>=mint);
Tcounts_=Tcounts(ts>=mint);
% pakt alleen de waarde die we nodig hebben terug achter het spectrum.
spds_=[spds(:,1),spds(:,find(ts>=mint)+1)];
% En berekent daar het gemiddelde van en dus de darkstroom.
meandark=[spds_(:,1),sum((spds_(:,2:end)),2)./(size(spds_,2)-1)];

figure(3);hold on
plot(ts_,Tcounts_,'ro')

n=1;
pdark=polyfit(ts_,Tcounts_,n);
d=0:0.1:max(ts_);
Tcounts_d=polyval(pdark,d);
plot(d,Tcounts_d,'k')

figure(1);subplot(1,3,3);
plot(meandark(:,1),meandark(:,2),'k','linewidth',1);

meandark=[meandark;[0,1]];%same format as spd from getOOspdf (last row and column = 2--> integrationtime)
darkmodel=[[n;zeros(n,1)],[pdark']];
darkmodel=[darkmodel;meandark];

%save darkmeas_model meandark pdark darkmodel
dlmwrite([MGV.droot,'Matlab\darkmodel.txt'],darkmodel,'delimiter','\t','precision','%1.6f');



%nieuwe dark at tx sec
tx=2;
newdark=[meandark(:,1),polyval(pdark,tx).*meandark(:,2)];
figure(1);subplot(1,3,2);
plot(newdark(:,1),newdark(:,2),'k','linewidth',2,'linestyle','--');
axis([360,830,-10,30])
    

figure,hold on
k=3;
for i=1:25;
    subplot(5,5,i);hold on
    plot(spds(:,1),spds(:,k+i+1).*Tcounts(k+i),'Color',cmap(i,:))
    tx=ts(k+i);
    newdark=[meandark(:,1),polyval(pdark,tx).*meandark(:,2)];
    plot(newdark(:,1),newdark(:,2),'r','linewidth',1,'linestyle','-');
end
    