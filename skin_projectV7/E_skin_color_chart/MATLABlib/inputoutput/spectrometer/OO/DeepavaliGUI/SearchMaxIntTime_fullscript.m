%search for max non saturated inttime
%required by getOOspdf and getOOspd_GUI(Deepavali)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning off
%Initialize parameters

if ~exist('Pr_maxcount','var');Pr_maxcount=0.8;end;%already defined
if ~exist('maxcCount_ratio','var');maxcCount_ratio=0.9;end;
if ~exist('display','var');display=0;end%already defined
FlagChangeInt=0;
target_count=maxCount*(Pr_maxcount+0.05);
IntTime_IncreaseRatio1=4;
tol_error_projected_time=1.1;
error_projected_inttime=100;
projected_large_than_maxint=0;
ratio_1=0.95;

%maxint=wrapper.getMaximumIntegrationTime(spectrometerIndex)./10^6;%get maxCount
MaxIntTime_user(MaxIntTime_user==0)=maxint*maxcCount_ratio;
maxint=min([maxint,MaxIntTime_user/maxcCount_ratio]);

Nspectra_0=1;Nspectra=Nspectra_0;%number of spectra to average to reduce influence of noise on fit
numberoflastmaxcounts2useinfitting=3;

db2=-specAD+4;MinimummaxcountRatioForNspectraIsOne=(2^(db2/2));%Noise ratio: cfr.: db2=2.*log2(I1/I0)

%--------------------------------------------------------------------------
% collect spectrum for inttime=minint (1st run)
%--------------------------------------------------------------------------
i=1;
IntTimes(i)=IntegrationTime;%start search at IntegrationTime
projected_inttime=IntegrationTime;

wrapper.setScansToAverage(spectrometerIndex,1);
wrapper.setCorrectForElectricalDark(spectrometerIndex,1);
wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,1);
wavs_ = wrapper.getWavelengths(spectrometerIndex);wavs_=wavs_(usepixels_);


%----------------------------------------------------------------------
% get stablespectrum for 1st run
%______________________________________________________________________
wrapper.setIntegrationTime(spectrometerIndex,IntTimes(i)*(10^6));
if display>=1;disp(sprintf('1st run: Checking IntegrationTime: %1.5f s',projected_inttime));end
n=2;
clear xy_ii satvals_ii maxcounts_ii COUNTS_ii;
ii=1;satvals_ii(ii)=0;
while (satvals_ii(ii)==0 & ii<=Nspectra) | maxcounts_ii(ii)<=0
    ii=ii+1;
    
    counts_ = wrapper.getSpectrum(spectrometerIndex);
    counts_=counts_(usepixels_);maxcounts_ii(ii)=max(counts_);COUNTS_ii(:,ii)=counts_;
    satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count));
    satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count))-2*wrapper.isSaturated(spectrometerIndex);
    std_ii(ii)=std(maxcounts_ii(n:end));
    xy_ii(ii,:)=[ii,IntTimes(i),projected_inttime,maxcounts_ii(ii),std(maxcounts_ii(n:end)),(std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end))),IntTimes(i)./projected_inttime,maxcounts_ii(ii)./maxCount,satvals_ii(ii),NaN];  %summary array 
    %[ii,Nspectra,ii>=Nspectra/2,((std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end)))),NaN,satvals_ii(ii),maxcounts_ii(ii)]
    if (Nspectra>1 & ii>=Nspectra/2 & ii>n & ((std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end)))<=0.05));break;end
end
maxcounts_ii=maxcounts_ii(n:end);
stdcounts(i)=std(maxcounts_ii);
maxcounts(i)=mean(maxcounts_ii);
satvals(i)=mean(satvals_ii(n:end))>0;
COUNTS_(:,i)=mean(COUNTS_ii')';counts_=COUNTS_(:,i);

nn=numberoflastmaxcounts2useinfitting;%use only last 3 for fitting
%maxcounts_valid=[maxcounts(satvals<=0 & (1:numel(maxcounts))>i-nn+1),IntTimes(satvals<=0 & (1:numel(maxcounts))>i-nn+1)];

if i>=nn;
    [p,S]=polyfit(maxcounts(satvals<=0 & (1:numel(maxcounts))>i-nn+1),IntTimes(satvals<=0 & (1:numel(maxcounts))>i-nn+1),1);
    [projected_inttime,DELTA]=polyval(p,target_count,S);
    if projected_inttime>minint
        projected_inttimes(i)=projected_inttime;
        DELTA=3.*DELTA;
        proj_intt_max=(projected_inttime+DELTA);proj_maxcount_max=(proj_intt_max-p(2))./p(1); 
        proj_intt_min=(projected_inttime-DELTA);proj_mincount_min=(proj_intt_min-p(2))./p(1); 
        errorontargetcount=proj_maxcount_max-proj_mincount_min;
        error_projected_inttime=std(projected_inttimes((1:numel(maxcounts))>i-nn+1));%use only last nn for checking stability of solution  
        %figure(3);plot(target_count,projected_inttime,'r.');errorbarxy(target_count,projected_inttime,errorontargetcount,DELTA);hold on;text(target_count,projected_inttime,sprintf('%1.0f',i));waituntilclicked;figure(3);
    
    else
        projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1;
    end
else
     IntTime_IncreaseRatio1_actual=min([IntTime_IncreaseRatio1,(maxCount.*maxcCount_ratio*ratio_1)./maxcounts(i)]);
     projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1_actual;
end
projected_inttime=projected_inttimes(i);

%check if larger than maxint
if projected_inttime>=maxint & maxcounts(i)/maxCount>=MinimummaxcountRatioForNspectraIsOne;
        projected_inttime=maxint.*maxcCount_ratio;
        projected_inttimes(i)=projected_inttime;
        projected_large_than_maxint=1;
else
        projected_large_than_maxint=0;
end

%xy(i,:)=[i,IntTimes(i),projected_inttimes(i),maxcounts(i),stdcounts(i),stdcounts(i)/maxcounts(i),IntTimes(i)./projected_inttime,maxcounts(i)./maxCount,satvals(i),NaN];   %summary array 
%figure(3);hold on;line([maxCount;maxCount],[0;projected_inttime*1.1]);plot(maxcounts(i),IntTimes(i),'b.');errorbarxy(maxcounts(i),IntTimes(i),stdcounts(i),[]);hold on;text(maxcounts(i),IntTimes(i),sprintf('%1.0f',i));waituntilclicked;figure(3);
%disp(sprintf('i=%1.0f t=%1.4f / %1.4f sat=%1.0f maxcount=%1.1f/ %1.3f, t_projected: %1.3f',i,IntTimes(i),IntTimes(i)/projected_inttime,satvals(i),maxcounts(i),maxcounts(i)./maxCount, projected_inttime))



%--------------------------------------------------------------------------
% collect spectra for increasing inttimes 
%--------------------------------------------------------------------------

while (maxcounts(i)<maxCount*(Pr_maxcount) & IntTimes(i)<=maxint  & projected_large_than_maxint==0) %& (projected_inttime+error_projected_inttime)/projected_inttime>=tol_error_projected_time
    i=i+1;
    Nspectra=Nspectra_0;
    IntTimes(i)=IntTimes(i-1)*IntTime_IncreaseRatio1;
    
    if ((IntTimes(i)>projected_inttime) | (((projected_inttime+error_projected_inttime)/projected_inttime)<=tol_error_projected_time)) & (maxcounts(i-1)/maxCount>=MinimummaxcountRatioForNspectraIsOne)
        IntTimes(i)=projected_inttime;
    end
    
    if maxcounts(i-1)/maxCount>=MinimummaxcountRatioForNspectraIsOne | IntTimes(i)>=maxint*maxcCount_ratio;Nspectra=1;end
    
   
    %----------------------------------------------------------------------
    % get stable spectrum for other spectra
    %______________________________________________________________________
    wrapper.setIntegrationTime(spectrometerIndex,IntTimes(i)*(10^6));
    if display>=1;disp(sprintf('Checking IntegrationTime: %1.5f s',IntTimes(i)));end
    n=2;
    clear xy_ii satvals_ii maxcounts_ii COUNTS_ii;
    ii=1;satvals_ii(ii)=0;
    while (satvals_ii(ii)==0 & ii<=Nspectra) | maxcounts_ii(ii)<=0
        ii=ii+1;
        counts_ = wrapper.getSpectrum(spectrometerIndex);
        counts_=counts_(usepixels_);maxcounts_ii(ii)=max(counts_);COUNTS_ii(:,ii)=counts_;
        satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count));
        satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count))-2*wrapper.isSaturated(spectrometerIndex);
        std_ii(ii)=std(maxcounts_ii(n:end));
        xy_ii(ii,:)=[ii,IntTimes(i),projected_inttime,maxcounts_ii(ii),std(maxcounts_ii(n:end)),(std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end))),IntTimes(i)./projected_inttime,maxcounts_ii(ii)./maxCount,satvals_ii(ii),NaN];  %summary array 
        if (Nspectra>1 & ii>=Nspectra/2 & ii>n & ((std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end)))<=0.05));break;end
    end
    maxcounts_ii=maxcounts_ii(n:end);
    stdcounts(i)=std(maxcounts_ii);
    maxcounts(i)=mean(maxcounts_ii);
    satvals(i)=mean(satvals_ii(n:end))>0;
    COUNTS_(:,i)=mean(COUNTS_ii')';counts_=COUNTS_(:,i);

    nn=numberoflastmaxcounts2useinfitting;%use only last 3 for fitting
    if i>=nn;
        [p,S]=polyfit(maxcounts(satvals<=0 & (1:numel(maxcounts))>i-nn+1),IntTimes(satvals<=0 & (1:numel(maxcounts))>i-nn+1),1);
        [projected_inttime,DELTA]=polyval(p,target_count,S);
        if projected_inttime>minint
            projected_inttimes(i)=projected_inttime;
            DELTA=3.*DELTA;
            proj_intt_max=(projected_inttime+DELTA);proj_maxcount_max=(proj_intt_max-p(2))./p(1); 
            proj_intt_min=(projected_inttime-DELTA);proj_mincount_min=(proj_intt_min-p(2))./p(1); 
            errorontargetcount=proj_maxcount_max-proj_mincount_min;
            error_projected_inttime=std(projected_inttimes((1:numel(maxcounts))>i-nn+1));%use only last nn for checking stability of solution  
            
            %figure(3);plot(target_count,projected_inttime,'r.');errorbarxy(target_count,projected_inttime,errorontargetcount,DELTA);hold on;text(target_count,projected_inttime,sprintf('%1.0f',i));waituntilclicked;figure(3);
    
        else
            projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1;
        end
    else
        IntTime_IncreaseRatio1_actual=min([IntTime_IncreaseRatio1,(maxCount.*maxcCount_ratio*ratio_1)./maxcounts(i)]);
        projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1_actual;
    end
    projected_inttimes;
    projected_inttime=projected_inttimes(i);

    %check if larger than maxint
    if projected_inttime>=maxint & maxcounts(i)/maxCount>=MinimummaxcountRatioForNspectraIsOne;
        projected_inttime=maxint.*maxcCount_ratio;
        projected_inttimes(i)=projected_inttime;
        projected_large_than_maxint=1;
    else
        projected_large_than_maxint=0;
    end
    
    
end
wrapper.setIntegrationTime(spectrometerIndex,minint*(10^6));%reduce latency time for final meas.
IntegrationTime=projected_inttime;
 %IntegrationTime=IntTimes(IntTimes<=maxint*maxcCount_ratio & maxcounts./maxCount<=maxcCount_ratio);IntegrationTime=IntegrationTime(IntegrationTime==max(IntegrationTime));
IntegrationTime(IntegrationTime>MaxIntTime_user)=MaxIntTime_user;
FlagChangeInt=1;
    
    
