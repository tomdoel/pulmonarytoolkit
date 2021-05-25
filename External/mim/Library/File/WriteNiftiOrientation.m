function WriteNiftiOrientation(inputfile, aff)
% By Ashkan Pakzad May 2021 (ashkanpakzad.github.io) 
% Copyright Ashkan Pakzad 2021. Distributed under MIT licence.

% Give name of nifti file ending either .nii or .nii.gz to have orientation
% written from given affine

% aff is a 4x4 matrix that represents the orientation of the given image in
% inputfile. As a nifti affine it maps the data coordinate directions ijk 
% to image coordinates in RAS. The last row of aff must be [0 0 0 1].
% The input aff matrix should not consider image spacing the top left 3x3
% matrix should only be of [-1,0,1]. The image spacing saved in the
% original image is written. 

% For more information regarding medical image orientation consider
% https://medium.com/@ashkanpakzad/understanding-3d-medical-image-orientation-for-programmers-fcf79c7beed0

% decompress and load
[~,~,ext] = fileparts(inputfile);
if strcmp(ext,'.gz')
    filename = string(gunzip(inputfile));
else
    filename = inputfile;
end

% Find Voxel dimensions; format = numdims,x,y,z,t
vox_dims = fieldread(76, 8, 'float');
vox_dims = vox_dims(2:4);

% write given affine into file
% only use sform, set qform to 0 and sform to 1
fieldwrite(0, 252, 'short'); % q
fieldwrite(1, 254, 'short'); % s
    
% add spacing info to input affine
aff(:,1) = aff(:,1)*vox_dims(1);
aff(:,2) = aff(:,2)*vox_dims(2);
aff(:,3) = aff(:,3)*vox_dims(3);

Sx = aff(1,:);
Sy = aff(2,:);
Sz = aff(3,:);

fieldwrite(Sx, 280, 'float')
fieldwrite(Sy, 296, 'float')
fieldwrite(Sz, 312, 'float')

% re-gzip if originally gzipped
if strcmp(ext,'.gz')
    gzip(filename);
    delete(filename)
end

% read and write functions

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
