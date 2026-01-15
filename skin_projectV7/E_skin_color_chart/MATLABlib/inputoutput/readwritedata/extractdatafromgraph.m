function data=extractdatafromgraph(h)

axesObjs = get(h, 'Children')  %axes handles

dataObjs = get(axesObjs, 'Children'); %handles to low-level graphics objects in axes   
%dataObjs = axesObjs.Children;

objTypes = get(dataObjs, 'Type')  %type of low-level graphics object   

xdata = get(dataObjs, 'XData');  %data from low-level grahics objects

ydata = get(dataObjs, 'YData');

zdata = get(dataObjs, 'ZData');

data=[xdata',ydata']