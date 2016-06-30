function info =vtk_read_header(filename)
% Function for reading the header of a Visualization Toolkit (VTK)
% 
% info  = vtk_read_header(filename);
%
% examples:
% 1,  info=vtk_read_header()
% 2,  info=vtk_read_header('volume.vtk');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.vtk', 'Read vtk-file');
    filename = [pathname filename];
end

fid=fopen(filename,'rb');
if(fid<0)
    fprintf('could not open file %s\n',filename);
    return
end

str = fgetl(fid);
info.Filename=filename;
info.Format=str(3:5); % Must be VTK
info.Version=str(end-2:end);
info.Header = fgetl(fid);
info.DatasetFormat= lower(fgetl(fid));
str = lower(fgetl(fid));
info.DatasetType = str(9:end);

readscalars=false;
while(~readscalars)
    str=fgetl(fid);
    s=find(str==' ',1,'first');
    if(~isempty(s))
        type=str(1:s-1); data=str(s+1:end);
    else
        type=''; data=str;
    end
    
    switch(lower(type))
        case 'dimensions'
            info.Dimensions=sscanf(data, '%d')';
		case 'point_data'
            info.NumberOfComponents = sscanf(data,'%d');
        case 'spacing'
            info.PixelDimensions=sscanf(data, '%lf')';
        case 'origin'
            info.Origin=sscanf(data, '%lf')';
        case 'color_scalars'
            readscalars=true;
            s=find(data==' ',1,'first');
            info.DataName=data(1:s-1);
            info.NumberOfComponents=sscanf(data(s+1:end),'%d');
            if ( info.NumberOfComponents == 1)
                info.PixelType='scalar';
            else
                info.PixelType='vector';
            end
            if(info.DatasetFormat(1)=='a')
                info.DataType='float';
            else
                info.DataType='uchar';
            end
        case 'scalars'
            readscalars=true;
            s=find(data==' ');
            info.DataName=data(1:s(1)-1);
			
            if ( length(s) > 1)
                info.DataType=data(s(1)+1:s(2)-1);
                info.NumberOfComponents=sscanf(data(s(2)+1:end),'%d');
            else
                info.DataType=data(s(1)+1:end);
			end
    end
end


switch(info.DataType)
    case 'char', info.BitDepth=8;
    case 'uchar', info.BitDepth=8;
    case 'short', info.BitDepth=16;
    case 'ushort', info.BitDepth=16;
    case 'int', info.BitDepth=32;
    case 'uint', info.BitDepth=32;
    case 'float', info.BitDepth=32;
    case 'double', info.BitDepth=64;
    otherwise, info.BitDepth=0;
end

b=ftell(fid);
str=fgetl(fid);
s=find(str==' ',1,'first');
type=str(1:s-1); data=str(s+1:end);
switch(lower(type))
    case 'lookup_table'
        info.TableName=data;
    otherwise
        fseek(fid,b,'bof');
end
info.HeaderSize=ftell(fid);
fclose(fid);
