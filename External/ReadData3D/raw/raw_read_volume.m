function V=raw_read_volume(info)
% function for reading volume of raw volume file
%
% volume = raw_read_volume(file-header)
%
% examples:
% 1: info = raw_read_header()
%    V = raw_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = raw_read_volume('test.raw');

if(~isstruct(info)), info=raw_read_header(info); end

% Open raw file
fid=fopen(info.Filename,'rb',lower(info.Alignment(1)));

% Seek volume data start
fseek(fid,info.Headersize,'bof');

switch(lower(info.DataType))
    case 'uchar';
        V = uint8(fread(fid,inf,'uint8'));
    case 'char';
        V = int8(fread(fid,inf,'int8'));
    case 'ushort';
        V = uint16(fread(fid,inf,'uint16'));
    case 'short';
        V = int16(fread(fid,inf,'int16'));
    case 'uint';
        V = uint32(fread(fid,inf,'uint32'));
    case 'int';
        V = int32(fread(fid,inf,'int32'));
    case 'float';
        V = single(fread(fid,inf,'single'));
    case 'double';        
        V = double(fread(fid,inf,'double'));
end
fclose(fid);

% Reshape the volume data to the right dimensions
V = reshape(V,info.Dimensions);

