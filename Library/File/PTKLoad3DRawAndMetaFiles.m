function dicom_image = PTKLoad3DRawAndMetaFiles(path, filenames, study_uid, reporting)
    % PTKLoad3DRawAndMetaFiles. Reads images from raw and meteheader files and returns as a PTKImage.
    %
    %     Note: Currently assumes that images are CT
    %
    %     Syntax
    %     ------
    %
    %         dicom_image = PTKLoad3DRawAndMetaFiles(path, filenames, study_uid, reporting)
    %
    %             dicom_image     is a PTKDicomImage class containing the image
    %             path            The path where the files are located. For the
    %                             current directory, use .
    %             filenames       the filename of the header file to load.
    %             reporting (optional) - an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    if nargin < 4
        reporting = CoreReportingDefault;
    end
    
    if nargin < 2
        reporting.Error('PTKLoad3DRawAndMetaFiles:NotEnoughArguments', 'PTKLoad3DRawAndMetaFiles requires a minimum of two arguments: the current path and  list of filenames');
    end

    if isa(filenames, 'CoreFilename')
        path = filenames.Path;
        filenames = filenames.Name;
    elseif isa(filenames{1}, 'CoreFilename')
        path = filenames{1}.Path;
        filenames = filenames{1}.Name;
    end
    
    % If a single file has been specified, put it into an array for consistency
    % with multiple filename syntax
    if ischar(filenames)
        filenames = {filenames};
    end

    if nargin < 3
        reporting.ShowWarning('PTKLoad3DRawAndMetaFiles:NoStudyUid', 'No study UID was specified - I am going to use the filename.', []);
        study_uid = filenames{1};
    end

    header_filename = fullfile(path, filenames{1});

    header_data = mha_read_header(header_filename);
    if isempty(header_data)
        reporting.Error('PTKLoad3DRawAndMetaFiles:MetaHeaderReadFailed', ['Unable to read metaheader data from ' header_filename]);
    end
    
    
    if isfield(header_data, 'TransformMatrix')
        transform_matrix = header_data.TransformMatrix;
        [new_dimension_order, flip_orientation] = PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromMhdCosines(transform_matrix(1:3), transform_matrix(4:6), transform_matrix(7:9), reporting);
    else        
        [new_dimension_order, flip_orientation] = PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromAnatomicalOrientation(header_data.AnatomicalOrientation, reporting);
    end

    % Note: for voxel size, we have a choice of ElementSpacing or ElementSize
    % We choose ElementSpacing as we assume all the voxels are contiguous
    voxel_size = header_data.PixelDimensions;
    
    original_image = mha_read_volume(header_data);
    reporting.UpdateProgressAndMessage(0, 'Reslicing');

    % We need to swap the X and Y dimensions in the loaded image
    image_dimensions = [2 1 3];
    new_dimension_order = image_dimensions(new_dimension_order);
    
    if ~isequal(new_dimension_order, [1, 2, 3])
        original_image = permute(original_image, new_dimension_order);
        voxel_size = voxel_size(new_dimension_order);        
    end
    for dimension_index = 1 : 3
        if flip_orientation(dimension_index)
            original_image = flipdim(original_image, dimension_index);
        end
    end
    
    rescale_slope = int16(1);
    rescale_intercept = int16(0);

    reporting.ShowWarning('PTKLoad3DRawAndMetaFiles:AssumedCT', 'No modality information - I am assuming these images are CT with slope 1 and intercept 0.', []);
    
    % Guess that images with some strongly negative values are from CT images while
    % others are MR
    min_value = min(original_image(:));
    if (min_value < -500)
        modality = 'CT';
    elseif (min_value >= 0)
        modality = 'MR';
    end
    
    dicom_image = PTKDicomImage(original_image, rescale_slope, rescale_intercept, voxel_size, modality, study_uid, header_data);
    dicom_image.Title = filenames{1};
end