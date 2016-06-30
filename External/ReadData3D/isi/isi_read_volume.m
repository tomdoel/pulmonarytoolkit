function [V] = isi_read_volume(info)
% function for reading volume of isi volume file
% isi_read_header(file-info)
%
% volume = isi_read_volume(file-header)
%
% examples:
% 1: info = isi_read_header()
%    V = isi_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = isi_read_volume('test.isi');

if(~isstruct(info)) info=isi_read_header(info); end

% Open isi file
fid=fopen(info.Filename,'rb');

  % Seek volume data start
  datasize=prod(info.Dimensions)*info.Bbp;
  fseek(fid,info.FileSize-datasize,'bof');

  % Read Volume data
  volsize(1:info.DimNum)=info.Dimensions;
  V = fread(fid,datasize,info.Type,0,'b');
fclose(fid);

% Reshape the volume data to the right dimensions
V = reshape(V,volsize);

