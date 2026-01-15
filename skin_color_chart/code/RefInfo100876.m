% 1 ~ 25th set are reflectance specular excluded
% 26 ~ 30th set are reflectance specular included
% 30th 'PCC SPI' is the UVO
% from 360 to 780 at 10nm in the order below:
% Ref: 0~100
% 30 sets of them
function [SetName,SetLocation]=RefInfo100876
SetName={
'DuPont spectra-master'  %,			1-672: 		672
'Munsell Limited Cascade' %			673-1392: 	720	
'MunSell' %  				1393-2952: 	1560
'NCS' % 					2953-4701:	1749
'Din'   %					4702-5682:	981
'Sun Chemical'  %				5683-32466:	26784
'foliages' %				32467-32487	21
'Calib'   %: (1-136)				32488-32623	136
'Face'%  (137-8706)				32624-41193	8570
'flowers' %(8707-8854)			41194-41341	148
'Graphic'  %:(8855-39478)			41342-71965	30624
'Krinov'%  :(39479-39824)			71966-72311	346
'leaves'%  : (39825-39916)			72312-72403	92
'paint'%  : (39917-40421)			72404-72908	505
'photo'%  :(40422-42725)			72909-75212	2304
'Printer' %:(42726-50581)			75213-83068	7856
'Textile'% :(50582-53413)			83069-85900	2832
'Oulu African'% 			85901-85924	24
'Oulu Caucasian'% 			85925-86227	303
'Oulu Oriental'% 			86228-86257	30
'RIT African'%              86258-86327	70
'RIT Caucasian'%			86328-86405	78
'RIT Oriental'% 			86406-86517	112
'RIT SubAsian'% 			86518-86577	60
'RIT Hispanic'% 			86578-86597	20
'Industry Cotton SPI'%  	86598-90625	4028
'Industry Plastic SPI'% 	90626-95963	5338
'Industry Pantone Polyester SPI'%	95964-97888	1925
'Industry Pantone Cotton SPI'   %	97889-99813	1925
'PCC SPI'                       % 99814-100876	1063
};

SetLocation=[
1, 672; 	%	672     DuPont spectra-master,		
673,1392; % 	720	   Munsell Limited Cascade	
 1393, 2952; %	1560  MunSell
2953,4701;%	1749  NCS 					
4702,5682;  %	981  Din				
5683,32466;	% 26784Sun Chemical		
32467,32487; % 	21  foliages		
32488,32623; % 	136Clib: (1-136)		
32624, 41193; %  8570 Face (137-8706)				
41194, 41341; %	148  flowers(8707-8854)		
41342,71965; %	30624  Graphic:(8855-39478)	
71966,72311; %	346  Krinov:(39479-39824)			
72312,72403;  %  92  leaves: (39825-39916)			
72404,72908; %	505  paint: (39917-40421)	
72909,75212;  % 2304  photo:(40422-42725)		
75213,83068; %	7856Printer:(42726-50581)			
83069,85900; %	2832Textile:(50582-53413)
85901,85924;% 24 Oulu African
85925,86227;% 303 Oulu Caucasian
86228,86257;% 30 Oulu Oriental
86258,86327;% 70 RIT African
86328,86405;% 78 RIT Caucasian
86406,86517;% 112 RIT Oriental
86518,86577;% 60 RIT SubAsian
86578,86597;% 20 RIT Hispanic
86598,90625;% 4028 Industry Cotton SPI
90626,95963;% 5338 Industry Plastic SPI
95964,97888;% 1925 Industry Pantone Polyester SPI
97889,99813;% 1925 Industry Pantone Cotton SPI
99814,100876;%	1063 PCC SPI
];