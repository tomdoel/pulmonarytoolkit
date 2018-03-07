function V = gipl_read_volume(info)
% function for reading volume of Guys Image Processing Lab (Gipl) volume file
% 
% volume = gipl_read_volume(file-header)
%
% examples:
% 1: info = gipl_read_header()
%    V = gipl_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = gipl_read_volume('test.gipl');

if(~isstruct(info)) info=gipl_read_header(info); end

% Open gipl file
fid=fopen(info.Filename','rb','ieee-be');

  % Seek volume data start
  if(info.ImageType==1), voxelbits=1; end
  if(info.ImageType==7||info.ImageType==8), voxelbits=8; end
  if(info.ImageType==15||info.ImageType==16), voxelbits=16; end
  if(info.ImageType==31||info.ImageType==32||info.ImageType==64), voxelbits=32; end
  if(info.ImageType==65), voxelbits=64; end
  
  datasize=prod(info.Dimensions)*(voxelbits/8);
  fsize=info.FileSize;
  fseek(fid,fsize-datasize,'bof');

  % Read Volume data
  volsize(1:3)=info.Dimensions;

  if(info.ImageType==1), V = logical(fread(fid,datasize,'bit1')); end
  if(info.ImageType==7), V = int8(fread(fid,datasize,'char')); end
  if(info.ImageType==8), V = uint8(fread(fid,datasize,'uchar')); end
  if(info.ImageType==15), V = int16(fread(fid,datasize,'short')); end 
  if(info.ImageType==16), V = uint16(fread(fid,datasize,'ushort')); end
  if(info.ImageType==31), V = uint32(fread(fid,datasize,'uint')); end
  if(info.ImageType==32), V = int32(fread(fid,datasize,'int')); end
  if(info.ImageType==64), V = single(fread(fid,datasize,'float')); end 
  if(info.ImageType==65), V = double(fread(fid,datasize,'double')); end 

fclose(fid);

% Reshape the volume data to the right dimensions
V = reshape(V,volsize);

