function V=hdr_read_volume(info)
% function for reading volume of HDR/IMG Analyze ( .hdr ) volume file
% 
% volume = hdr_read_volume(file-header)
%
% examples:
% 1: info = hdr_read_volume(()
%    V = hdr_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = hdr_read_volume(('test.hdr');
%
if(~isstruct(info)), info=hdr_read_header(info); end

if(exist('analyze75read','file')>0)
    V = analyze75read(info);
else
    V = get_analyze_volume(info);
end

function V = get_analyze_volume(info)
% Open img file
[folder filename] = fileparts(info.Filename);
Filename = fullfile(folder, [filename '.img']);

fid=fopen(Filename,'rb',info.ByteOrder);
 datasize=prod(info.Dimensions)*(info.BitDepth/8);
 fseek(fid,0,'bof');
 switch(info.ImgDataType)
     case 'DT_BINARY'
         V = logical(fread(fid,datasize,'bit1'));
     case 'DT_UNSIGNED_CHAR'
         V = uint8(fread(fid,datasize,'uchar')); 
     case 'DT_SIGNED_SHORT'
         V = int16(fread(fid,datasize,'short')); 
     case 'DT_SIGNED_INT'
         V = int32(fread(fid,datasize,'int'));
     case 'DT_FLOAT'
         V = single(fread(fid,datasize,'float'));     
     case 'DT_DOUBLE'
         V = double(fread(fid,datasize,'double'));
     case 'DT_COMPLEX'
     case 'DT_RGB'
     case 'DT_ALL'
 end
fclose(fid);

% Reshape the volume data to the right dimensions
V = reshape(V,info.Dimensions);


