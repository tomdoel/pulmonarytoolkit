function V = vtk_read_volume(info)
% Function for reading the volume from a Visualization Toolkit (VTK)
% 
% volume = tk_read_volume(file-header)
%
% examples:
% 1: info = vtk_read_header()
%    V = vtk_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = vtk_read_volume('test.vtk');

if(~isstruct(info)), info=vtk_read_header(info); end

% Open file
fid=fopen(info.Filename','rb','ieee-be');
% Skip header
fseek(fid,info.HeaderSize,'bof');

datasize=prod(info.Dimensions)*info.BitDepth/8;
% Read the Data
switch(lower(info.DatasetFormat(1)))
    case 'b'
        switch(info.DataType)
            case 'char'
                 V = int8(fread(fid,datasize,'char')); 
            case 'uchar'
                V = uint8(fread(fid,datasize,'uchar')); 
            case 'short'
                V = int16(fread(fid,datasize,'short')); 
            case 'ushort'
                V = uint16(fread(fid,datasize,'ushort')); 
            case 'int'
                 V = int32(fread(fid,datasize,'int')); 
            case 'uint'
                 V = uint32(fread(fid,datasize,'uint')); 
            case 'float'
                 V = single(fread(fid,datasize,'float'));   
            case 'double'
                V = double(fread(fid,datasize,'double'));
        end
    case 'a'
        t=prod(info.Dimensions);
        switch(info.DataType)
            case 'char', type='int8';
            case 'uchar', type='uint8';
            case 'short', type='int16';
            case 'ushort', type='uint16';
            case 'int', type='int32';
            case 'uint', type='uint32';
            case 'float', type='single';
            case 'double', type='double';
            otherwise, type='double';
        end
        V=zeros([1 t],type);
        for i=1:t, V(i)=str2double(fgetl(fid)); end
end

fclose(fid);
V = reshape(V,info.Dimensions);


