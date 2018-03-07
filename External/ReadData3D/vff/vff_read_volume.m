function V = vff_read_volume(info)
% Function for reading the volume from a Visualization Toolkit (VTK)
%
% volume = vff_read_volume(file-header)
%
% examples:
% 1: info = vff_read_header()
%    V = vff_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = vff_read_volume('test.vff');

if(~isstruct(info)), info=vff_read_header(info); end

% Open file
fid=fopen(info.Filename','rb','ieee-be');
% Skip header
fseek(fid,info.HeaderSize,'bof');

datasize=prod(info.Dimensions)*info.BitDepth/8;

% Read the Data
info.DataType='short';
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

fclose(fid);
V = reshape(V,info.Dimensions);


