function [info] =gipl_read_header(filename)
% function for reading header of  Guys Image Processing Lab (Gipl) volume file
%
% info  = gipl_read_header(filename);
%
% examples:
% 1,  info=gipl_read_header()
% 2,  info=gipl_read_header('volume.gipl');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.gipl', 'Read gipl-file');
    filename = [pathname filename];
end

fid=fopen(filename,'rb','ieee-be');
if(fid<0)
    fprintf('could not open file %s\n',filename);
    return
end

trans_type{1}='binary'; trans_type{7}='char'; trans_type{8}='uchar'; 
trans_type{15}='short'; trans_type{16}='ushort'; trans_type{31}='uint'; 
trans_type{32}='int';  trans_type{64}='float';trans_type{65}='double'; 
trans_type{144}='C_short';trans_type{160}='C_int';  trans_type{192}='C_float'; 
trans_type{193}='C_double'; trans_type{200}='surface'; trans_type{201}='polygon';

trans_orien{0+1}='UNDEFINED'; trans_orien{1+1}='UNDEFINED_PROJECTION'; 
trans_orien{2+1}='AP_PROJECTION';  trans_orien{3+1}='LATERAL_PROJECTION'; 
trans_orien{4+1}='OBLIQUE_PROJECTION'; trans_orien{8+1}='UNDEFINED_TOMO'; 
trans_orien{9+1}='AXIAL'; trans_orien{10+1}='CORONAL'; 
trans_orien{11+1}='SAGITTAL'; trans_orien{12+1}='OBLIQUE_TOMO';

offset=256; % header size

%get the file size
fseek(fid,0,'eof');
fsize = ftell(fid); 
fseek(fid,0,'bof');

sizes=fread(fid,4,'ushort')';
if(sizes(4)==1), maxdim=3; else maxdim=4; end
sizes=sizes(1:maxdim);
image_type=fread(fid,1,'ushort');
scales=fread(fid,4,'float')';
scales=scales(1:maxdim);
patient=fread(fid,80, 'uint8=>char')';
matrix=fread(fid,20,'float')';
orientation=fread(fid,1, 'uint8')';
par2=fread(fid,1, 'uint8')';
voxmin=fread(fid,1,'double');
voxmax=fread(fid,1,'double');
origin=fread(fid,4,'double')';
origin=origin(1:maxdim);
RescaleIntercept=fread(fid,1,'float');
RescaleSlope=fread(fid,1,'float');

interslicegap=fread(fid,1,'float');
user_def2=fread(fid,1,'float');
magic_number= fread(fid,1,'uint');
if (magic_number~=4026526128), error('file corrupt - or not big endian'); end
fclose('all');

info.Filename=filename;
info.FileSize=fsize;
info.Dimensions=sizes;
info.PixelDimensions=scales;
info.ImageType=image_type;
info.Patient=patient;
info.Matrix=matrix;
info.Orientation=orientation;
info.VoxelMin=voxmin;
info.VoxelMax=voxmax;
info.Origin=origin;
info.RescaleIntercept=RescaleIntercept;
info.RescaleSlope=RescaleSlope;
info.InterSliceGap=interslicegap;
info.UserDef2=user_def2;
info.Par2=par2;
info.Offset=offset;


