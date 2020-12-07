function writeniiaffonly(inputfile, aff)

% decompress and load
[~,~,ext] = fileparts(inputfile);
if strcmp(ext,'.gz')
    filename = string(gunzip(inputfile));
else
    filename = inputfile;
end

% Find number of Dimensions & Voxel dimensions
fid=fopen(filename);
fseek(fid,76,'bof') ; % vox size in header
vox_dims = fread(fid,8,'float'); % format = numdims,x,y,z,t
fclose(fid);
vox_dims = vox_dims(2:4);


%% write given affine into file

% only use sform, set qform to 0 and sform to 1
fieldwrite(0, 252, 'short'); % q
fieldwrite(1, 254, 'short'); % s
    
% add spacing info to input affine
aff(:,1) = aff(:,1)*vox_dims(1);
aff(:,2) = aff(:,2)*vox_dims(2);
aff(:,3) = aff(:,3)*vox_dims(3);

nsx = aff(1,:);
nsy = aff(2,:);
nsz = aff(3,:);

fieldwrite(nsx, 280, 'float')
fieldwrite(nsy, 296, 'float')
fieldwrite(nsz, 312, 'float')


if strcmp(ext,'.gz')
    gzip(filename);
    delete(filename)
end

%% func

function fieldwrite(field, offset, precision)
    % open file and read binary field from given offset into size and type.
    fid=fopen(filename, 'r+');
    fseek(fid,offset,'bof');
    fwrite(fid,field,precision);
    fclose(fid);
end
end
