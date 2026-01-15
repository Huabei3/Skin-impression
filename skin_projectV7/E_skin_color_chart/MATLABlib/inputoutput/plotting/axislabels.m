function axislabels(Xaxis,Yaxis)


set(gca,'XTick',1:1:length(Xaxis));
set(gca,'XTickLabel',Xaxis);

set(gca,'YTick',1:1:length(Yaxis));
set(gca,'YTickLabel',Yaxis);
end