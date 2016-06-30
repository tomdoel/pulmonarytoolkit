function V = nii_read_volume(info)
% function for reading volume of NifTi ( .nii ) volume file
% nii_read_header(file-info)
%
% volume = nii_read_volume(file-header)
%
% examples:
% 1: info = nii_read_header()
%    V = nii_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = nii_read_volume('test.nii');

if(~isstruct(info)) info=nii_read_header(info); end

% Open v3d file
fid=fopen(info.Filename,'rb');

  % Seek volume data start
  datasize=prod(info.Dimensions)*(info.BitVoxel/8);
  fsize=info.Filesize;
  fseek(fid,fsize-datasize,'bof');

  % Read Volume data
  switch(info.DataTypeStr)
      case 'INT8'
        V = int8(fread(fid,datasize,'int8'));
      case 'UINT8'
        V = uint8(fread(fid,datasize,'uint8'));
      case 'INT16'
        V = int16(fread(fid,datasize,'int16'));
      case 'UINT16'
        V = uint16(fread(fid,datasize,'uint16'));
      case 'INT32'
        V = int32(fread(fid,datasize,'int32'));
      case 'UINT32'
        V = uint32(fread(fid,datasize,'uint32'));
      case 'INT64'
        V = int64(fread(fid,datasize,'int64'));
      case 'UINT64'
        V = uint64(fread(fid,datasize,'uint64'));    
      otherwise
        V = uint8(fread(fid,datasize,'uint8'));
  end
fclose(fid);

% Reshape the volume data to the right dimensions
V = reshape(V,info.Dimensions);

