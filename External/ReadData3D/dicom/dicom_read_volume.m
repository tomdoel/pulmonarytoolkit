function voxelvolume = dicom_read_volume(info)
% function for reading volume of Dicom files
% 
% volume = dicom_read_volume(file-header)
%
% examples:
% 1: info = dicom_read_header()
%    V = dicom_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = dicom_read_volume('volume.dcm');

if(~isstruct(info)) info=dicom_read_header(info); end

voxelvolume=dicomread(info.Filenames{1});
nf=length(info.Filenames);
if(nf>1)
    % Initialize voxelvolume
    voxelvolume=zeros(info.Dimensions,class(voxelvolume));
    % Convert dicom images to voxel volume
    h = waitbar(0,'Please wait...');
    for i=1:nf,
        waitbar(i/nf,h)
		I=dicomread(info.Filenames{i});
        if((size(I,3)*size(I,4))>1)
            voxelvolume=I; break;
        else
            voxelvolume(:,:,i)=I;
        end
    end
    close(h);
end


