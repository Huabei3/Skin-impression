function [cmf,k]=selectcmf(observer)
global cmf2 cmf10

switch observer
    case 2  
    cmf=cmf2;k=683;
    case 10
    cmf=cmf10;k=683;6;
end
end