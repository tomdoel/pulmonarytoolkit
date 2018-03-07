function V = par_read_volume(info)
% Function for reading the volume of a Philips Par / Rec  MR V4.* file 
%
% volume = par_read_volume(file-header)
%
% examples:
% 1: info = par_read_header()
%    V = par_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2),1)),[]);
%
% 2: V = par_read_volume('test.par');

if(~isstruct(info)), info=par_read_header(info); end

% Open file
fid=fopen(info.FilenameREC','rb','ieee-le');
% Skip header
fseek(fid,0,'bof');

datasize=prod(info.Dimensions)*info.BitDepth/8;

% Read the Data
switch(info.BitDepth)
    case 8
        info.DataType='char';
    case 16
        info.DataType='short';
    case 32
        info.DataType='float';
    case 64
        info.DataType='double';
end

switch(info.DataType)
    case 'char'
        V = int8(fread(fid,datasize,'char=>int8'));
    case 'uchar'
        V = uint8(fread(fid,datasize,'uchar=>uint8'));
    case 'short'
        V = int16(fread(fid,datasize,'short=>int16'));
    case 'ushort'
        V = uint16(fread(fid,datasize,'ushort=>uint16'));
    case 'int'
        V = int32(fread(fid,datasize,'int=>int32'));
    case 'uint'
        V = uint32(fread(fid,datasize,'uint=>uint32'));
    case 'float'
        V = single(fread(fid,datasize,'float=>single'));
    case 'double'
        V = double(fread(fid,datasize,'double=>double'));
end

fclose(fid);
V = reshape(V,info.Dimensions);


