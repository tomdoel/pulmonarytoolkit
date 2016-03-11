function info =vff_read_header(filename)
% Function for reading the header of a Micro CT ( VFF ) file
% ( Ge Medical, Elsinct (Esteem MR) )
%
% info  = vff_read_header(filename);
%
% examples:
% 1,  info=vff_read_header()
% 2,  info=vff_read_header('volume.vff');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.vff', 'Read vff-file');
    filename = [pathname filename];
end

fid=fopen(filename,'rb');
if(fid<0)
    fprintf('could not open file %s\n',filename);
    return
end
info.Filename=filename;
t=0;
while(true)
    str=fgetl(fid);
    s=find(str=='=',1,'first');
    if(isempty(s)), s=length(str); end
    type=str(1:s-1);  data=str(s+1:end);
    if(isempty(type)), break; end
    if(isempty(data)),
        data='';
    else
        if(data(end)==';'),
            if(length(data)>1),data=data(1:end-1); else data=''; end
        end
    end
    
    switch(lower(type))
        case 'size'
            info.Dimensions=sscanf(data, '%d')';
        case 'bits'
            info.BitDepth=sscanf(data, '%d')';
        case 'rank'
            info.Rank=sscanf(data, '%d')';
        case 'bands'
            info.Bands=sscanf(data, '%d')';
        case 'y_bin'
            info.yBin=sscanf(data, '%d')';
        case 'z_bin'
            info.zBin=sscanf(data, '%d')';
        case 'rfan_y'
            info.RfanY=sscanf(data, '%lf')';
        case 'rfan_z'
            info.RfanZ=sscanf(data, '%lf')';
        case 'min'
            info.Min=sscanf(data, '%lf')';
        case 'max'
            info.Max=sscanf(data, '%lf')';
        case 'water'
            info.Water=sscanf(data, '%lf')';
        case 'air'
            info.Air=sscanf(data, '%lf')';
        case 'bonehu'
            info.BoneHU=sscanf(data, '%lf')';
        case 'angle_increment'
            info.AngleIncrement=sscanf(data, '%lf')';
        case 'center_of_rotation'
            info.CenterOfRotation=sscanf(data, '%lf')';
        case 'central_slice'
            info.CentralSlice=sscanf(data, '%lf')';
        case 'spacing'
            info.PixelDimensions=sscanf(data, '%lf')';
        case 'origin'
            info.Origin=sscanf(data, '%lf')';
        otherwise
            info.(type)=data;
    end
end
datasize=prod(info.Dimensions)*(info.BitDepth/8);
fseek(fid,-datasize,'eof');
info.HeaderSize=ftell(fid);
fclose(fid);
