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

    if ~isa(image_to_save, 'PTKImage')
        reporting.Error('MimSaveAsNifti:InputMustBePTKImage', 'Requires a PTKImage as input');
    end

    image_data = image_to_save.RawImage;
    
    full_filename = fullfile(path, filename);

    resolution = image_to_save.VoxelSize([2, 1, 3]);
    
    offset = [0 0 0];
    if isa(image_data, 'PTKDicomImage')
        metadata = image_data. MetaHeader;
        if isfield(metadata, 'Offset')
            offset = metadata.Offset;
        end
    end
    
    image_data = permute(image_data, [2, 1, 3]);
    image_data = flip(flip(flip(image_data, 3), 2), 1);
    
    nii_data = make_nii(image_data, resolution, offset, [], image_to_save.Title);
    save_nii(nii_data, full_filename);
end

