function MimSaveAsNifti(image_to_save, path, filename, reporting)
    % MimSaveAsNifti. Writes out a PTKImage in NIFTI format
    %
    %     Syntax
    %     ------
    %
    %         MimSaveAsNifti(image_data, path, filename, data_type, orientation, reporting)
    %
    %             image_to_save   is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved
    %             path, filename  specify the location to save the NIFTI data.
    %             reporting       an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        
    
    if nargin < 4
        reporting = CoreReportingDefault();
    end
    
    if ~isa(image_to_save, 'PTKImage')
        reporting.Error('MimSaveAsNifti:InputMustBePTKImage', 'Requires a PTKImage as input');
    end

    % check if .nii.gz given
    [~,~,ext] = fileparts(filename);
    if strcmp(ext,'.gz')
        compressed = 1;
        filename = filename(1:end-3);
    else
        compressed = 0;
    end
    
    image_data = image_to_save.RawImage;
    
    full_filename = fullfile(path, filename);

    resolution = image_to_save.VoxelSize([2, 1, 3]);
    
    offset = [0 0 0];
    if isa(image_to_save, 'PTKDicomImage')
        metadata = image_to_save. MetaHeader;
        if isfield(metadata, 'ImagePositionPatient')
            offset = metadata.ImagePositionPatient;
        end
    end
    
    image_data = permute(image_data, [2, 1, 3]);
    image_data = flip(image_data, 3); % only flip last dimension

    
    nii_data = make_nii(image_data, resolution, offset, [], image_to_save.Title);
    save_nii(nii_data, full_filename);
    
    % set orientation
    if isa(image_to_save, 'PTKDicomImage')
        % get LPS form from dicom
        if isfield(metadata, 'ImagePositionPatient')
            dicomorientation = metadata.ImageOrientationPatient;
            d1 = dicomorientation(1:3);
            d2 = dicomorientation(4:6);
            d3 = cross(d1,d2);
            LPS_affine4 = [d1, d2, d3, offset];
            LPS_affine4 = [LPS_affine4; [0,0,0,1]];
            % convert to RAS for nifti
            RAS_affine4 = diag([-1,-1,1,1])*LPS_affine4;
            WriteNiftiOrientation(full_filename, RAS_affine4)
        end
    end
    
    % if .nii.gz save as .nii.gz
    if compressed == 1
        gzip(full_filename)
    end

end

