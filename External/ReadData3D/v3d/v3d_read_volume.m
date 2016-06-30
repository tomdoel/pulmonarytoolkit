function V = v3d_read_volume(info)
% function for reading volume of V3D Philips Scanner ( .v3d ) 
% volume file
% 
% volume = v3d_read_volume(file-header)
%
% examples:
% 1: info = v3d_read_header()
%    V = v3d_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = v3d_read_volume('test.v3d');

if(~isstruct(info)) info=v3d_read_header(info); end

% Open v3d file
f=fopen(info.Filename,'rb');

  % Seek volume data start
  datasize=prod(info.Dimensions)*(info.Voxelbits/8);
  fseek(f,info.Filesize-datasize,'bof');

  % Read Volume data
  V = uint16(fread(f,datasize,'uint16'));
fclose(f);

% Reshape the volume data to the right dimensions
V = reshape(V,info.Dimensions);

