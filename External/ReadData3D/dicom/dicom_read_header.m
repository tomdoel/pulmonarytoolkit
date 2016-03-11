function info=dicom_read_volume(filename)
% function for reading header of Dicom volume file
%
% info = dicom_read_header(filename);
%
% examples:
% 1,  info=dicom_read_header()
% 2,  info=dicom_read_header('volume.dcm');

% Check if function is called with folder name
if(exist('filename','var')==0)
    dirname=''; 
    [filename, dirname] = uigetfile( {'*.dcm;*.dicom', 'Dicom Files'; '*.*', 'All Files (*.*)'}, 'Select a dicom file',dirname);
    if(filename==0), return; end
    filename=[dirname filename];
end

% Read directory for Dicom File Series
datasets=dicom_folder_info(filename,false);
if(isempty(datasets))
    datasets=dicom_folder_info(filename,true);
end

if(length(datasets)>1)
    c=cell(1,length(datasets));
    for i=1:length(datasets)
        c{i}=datasets(i).Filenames{1};
    end
    id=choose_from_list(c,'Select a Dicom Dataset');
    datasets=datasets(id);
end

info=datasets.DicomInfo;
info.Filenames=datasets.Filenames;
info.PixelDimensions=datasets.Scales;
info.Dimensions=datasets.Sizes;
