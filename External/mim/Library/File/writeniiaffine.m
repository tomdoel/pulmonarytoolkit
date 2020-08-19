function writeniiaffine(inputfile, aff)

% decompress and load
[~,~,ext] = fileparts(inputfile);
if strcmp(ext,'.gz')
    filename = string(gunzip(inputfile));
else
    filename = inputfile;
end

% Find number of Dimensions & Voxel dimensions
fid=fopen(filename);
fseek(fid,40,'bof') ; % dim number in header
img_dims = fread(fid,8,'short'); % format = numdims,x,y,z,t
fseek(fid,76,'bof') ; % vox size in header
vox_dims = fread(fid,8,'float'); % format = numdims,x,y,z,t
fclose(fid);
img_dims = img_dims(2:img_dims(1)+1);
vox_dims = vox_dims(2:4);

fid=fopen(filename);
% move to a position 70 bytes from the beginning of the file.
fseek(fid,70,'bof');
% Read the datatype code
datatype_code=fread(fid,1,'short');
% always remember to close the file when finished!
fclose(fid);

switch datatype_code
case 2
datatype_string = 'uint8';
case 4
datatype_string = 'int16';
case 8
datatype_string = 'int32';
case 16
datatype_string = 'float';
case 64
datatype_string = 'double';
otherwise
error('This datatype is not supported');
end

% open the file
fid=fopen(filename);
% move to the start of the image data.
fseek(fid,352,'bof');
% Read the image into a 1D vector
V=fread(fid,prod(img_dims),datatype_string);
fclose(fid);
% Reshape the image so it has the correct dimensions
% V=reshape(V,img_dims');


%% check orientation method
% read qform
qformcode = fieldread(252, 1, 'short');
sformcode = fieldread(254, 1, 'short');
if qformcode > 0
    % get quaternian offset
    offsetx = fieldread(268, 1, 'float');
    offsety = fieldread(272, 1, 'float');
    offsetz = fieldread(276, 1, 'float');
elseif sformcode > 0
    sx = fieldread(280, 16, 'float');
    sy = fieldread(296, 16, 'float');
    sz = fieldread(312, 16, 'float');
    offsetx = sx(1,4);
    offsety = sx(2,4);
    offsetz = sx(3,4);
%     s3daff = [sx(1:3)';sy(1:3)';sz(1:3)'];
%     
%     s3daff_norm = s3daff./s3daff;
%     s3daff_norm(isnan(s3daff_norm)) = 0;
% 
%     axes = [1,2,3]; % default
%     for i = 1:3
%         vec = s3daff_norm(:,i);
%         axes(i) = find(vec);
%     end
else 
    error('cannot edit orientation on this file')
    % uses old analyze, code not yet written for this file type.
end


%% write given affine into file
% if strcmp(orientationmethod,'qform')
%     % convert affine matrix into R
%     
%     % convert R into quaternion
%     a = 0.5 * sqrt(1+aff(1,1)+aff(2,2)+aff(3,3));
%     b = 0.25 * (aff(3,2)-aff(2,3)) / a;
%     c = 0.25 * (aff(1,3)-aff(3,1)) / a;
%     d = 0.25 * (aff(2,1)-aff(1,2)) / a;
%     
%     fieldwrite(b, 256, 'float')
%     fieldwrite(c, 260, 'float')
%     fieldwrite(d, 264, 'float')

% only use sform, set qform to 0 and sform to 1
fieldwrite(0, 252, 'short'); % q
fieldwrite(1, 254, 'short'); % s
    
% add spacing info to input affine
aff(:,1) = aff(:,1)*vox_dims(1);
aff(:,2) = aff(:,2)*vox_dims(2);
aff(:,3) = aff(:,3)*vox_dims(3);

nsx = [aff(1,:), offsetx];
nsy = [aff(2,:), offsety];
nsz = [aff(3,:), offsetz];

fieldwrite(nsx, 280, 'float')
fieldwrite(nsy, 296, 'float')
fieldwrite(nsz, 312, 'float')


if strcmp(ext,'.gz')
    gzip(filename);
    delete(filename)
end

%% func

function field = fieldread(offset, size, precision)
    % open file and read binary field from given offset into size and type.
    fid=fopen(filename);
    fseek(fid,offset,'bof');
    field = fread(fid,size,precision);
    fclose(fid);
end

function fieldwrite(field, offset, precision)
    % open file and read binary field from given offset into size and type.
    fid=fopen(filename, 'r+');
    fseek(fid,offset,'bof');
    fwrite(fid,field,precision);
    fclose(fid);
end
end
