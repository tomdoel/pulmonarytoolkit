function PTKSaveAsMetaheaderAndRaw(image_data, path, filename, data_type, reporting)
    % PTKSaveAsMetaheaderAndRaw. Writes out a PTKImage in metaheader & raw format
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveAsMetaheaderAndRaw(image_data, path, filename, data_type, orientation, reporting)
    %
    %             image_data      is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             data_type
    %             reporting       A PTKReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    if ~isa(image_data, 'PTKImage')
        reporting.Error('PTKSaveAsMetaheaderAndRaw:InputMustBePTKImage', 'Requires a PTKImage as input');
    end

    orientation = ChooseOrientation(image_data.VoxelSize);
    
    original_image = image_data.RawImage;
    
    if (strcmp(data_type, 'char') || strcmp(data_type, 'uint8'))
        scale_factor = 255.0;
        limits = image_data.Limits;
        min_image = limits(1);
        max_image = limits(2);
        min_scale = 0;
        max_scale = 2048;
        if (min_image < min_scale)
            min_scale = min_image;
        end
        if (max_image > max_scale)
            max_scale = max_image;
        end
        
        % Rescale image only if the range cannot be contained in 8 bits
        scale_range = max_image - min_image;
        if (scale_range <= 255)
            scale = 1;
        else
            reporting.ShowWarning('PTKSaveAsMetaheaderAndRaw:ImageRescaled', 'Image data has been rescaled', []);
            scale = scale_factor/double(max_scale - min_scale);
        end
        image = uint8(scale*(original_image - min_scale));
        
    else
        image = original_image;
    end
    
    full_filename = fullfile(path, filename);

    resolution = image_data.VoxelSize([1, 2, 3]);
    
    offset = '0 0 0';
    if isa(original_image, 'PTKDicomImage')
        metadata = original_image.MetaHeader;
        if isfield(metadata, 'Offset')
            offset = metadata.Offset;
        end
    end
    
    PTKWrite3DMetaFile(full_filename, image, resolution, data_type, offset, orientation, reporting);  
end

% Select an image orientation in which the image will be saved
function orientation = ChooseOrientation(voxel_size)
    orientation = PTKImageOrientation.Axial;
    [sorted_voxel_size, sorted_voxel_size_index] = sort(voxel_size, 'descend');
    if abs(sorted_voxel_size(1) - sorted_voxel_size(2)) > abs(sorted_voxel_size(2) - sorted_voxel_size(3))
        if sorted_voxel_size_index(1) == 1
            orientation = PTKImageOrientation.Coronal;
        end
    end
end
