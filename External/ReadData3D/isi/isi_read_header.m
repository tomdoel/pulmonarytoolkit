function [info] = isi_read_header(filename)
% function for reading header of isi volume file
%
% info = isi_read_header(filename);
%
% examples:
% 1,  info=isi_read_header()
% 2,  info=isi_read_header('volume.isi');


if(exist('filename','var')==0)
    [filename, pathname, filterindex] = uigetfile('*.isi', 'Read isi-file');
    filename = [pathname filename];
end

fid=fopen(filename,'rb');
if(fid<0)
    fprintf('could not open file %s\n',filename);
    return
end

%get the file size
fseek(fid,0,'eof');
fsize = ftell(fid); 
fseek(fid,0,'bof');

headerl=1000; if (headerl>fsize), headerl=fsize; end
vdata = uint8(fread(fid,headerl,'uint8'));
fclose('all');

%sort header data in lines%
p=0;o=1;
clear regel;
for i=1:length(vdata)
    if(vdata(i)==10)
        headerline{o}=char(regel);
        clear regel;
        o=o+1; p=0;
    else
        p=p+1;
        lenregel(o)=p;
        regel(p)=vdata(i);    
    end
end

info=struct('Filename',filename,'Format',headerline{1},'FileSize',fsize,'DimNum',str2num(headerline{2}),'Dimensions',str2num(headerline{3}),'Bbp',str2num(headerline{4}),'Type',headerline{5});
info.PixelDimensions=[0 0 0];
if((o>5)&&strcmp(headerline{6},'isiGeometry'))
    info.GeoFormat=headerline{6};
    info.GeoDimensions=str2num(headerline{7});
    info.GeoOrgin=str2num(headerline{8});
    for d=1:str2num(headerline{7})
         info=setfield(info,['GeoVector' num2str(d)], str2num(headerline{8+d}));
    end
    info=setfield(info,['GeoExtent'], str2num(headerline{9+d}));
end