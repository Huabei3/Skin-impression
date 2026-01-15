function out=IOPort_(tasktype, g_serialPort_,data)
global g_serialPort;
switch lower(tasktype)
    case 'verbosity'
        out=0;
    case 'openserialport'
        if sum(ismember(g_serialPort_(1:3),'COM'))==3;g_serialPort_=g_serialPort_(4:end);end
        g_serialPort=serial(['COM',g_serialPort_]);
        set(g_serialPort,'Baudrate',9600,'DataBits',8,'Parity','none','StopBits',1,'RequestToSend','off')
        fopen(g_serialPort);
        data
        for i=1:numel(data);data(i),fprintf(g_serialPort,'%s\n',data(i),'async'),end
        out=g_serialPort;
    case 'write'
        data
        sprintf('%s\n',data)
        if ~isempty(g_serialPort);h=get(g_serialPort,'Status'),ismember(lower(h),'open'),sum(ismember(lower(h),'open'))==4,if sum(ismember(lower(h),'open'))==5;else;fopen(g_serialPort);end;end
        fprintf(g_serialPort,'%s\n',data,'async')
        g_serialPort
        out=0
    case 'read'
        out = fscanf(g_serialPort_);
    case 'close'
        fclose(g_serialPort_);
end

