function ptk_image = PTKLoadOtherFormat(path, filenames, study_uid, image_file_format, reporting)
    % PTKLoadOtherFormat. Reads images from various_formats returns as a PTKImage.
    %
    %     Note: Currently assumes that images are CT
    %
    %     Syntax
    %     ------
    %
    %         ptk_image = PTKLoadOtherFormat(path, filenames, study_uid, reporting)
    %
    %             ptk_image     is a PTKDicomImage class containing the image
    %             path            The path where the files are located. For the
    %                             current directory, use .
    %             filenames       the filename of the header file to load.
    %             image_file_format   enumeration of PTKImageFileFormat
    %                                 describing the file format
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
        reporting.Error('PTKLoadOtherFormat:NotEnoughArguments', 'PTKLoadOtherFormat requires a minimum of two arguments: the current path and  list of filenames');
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
        reporting.ShowWarning('PTKLoadOtherFormat:NoStudyUid', 'No study UID was specified - I am going to use the filename.', []);
        study_uid = filenames{1};
    end
    
    header_filename = fullfile(path, filenames{1});
    
    switch image_file_format
        case PTKImageFileFormat.Analyze
            header_data = hdr_read_header(header_filename);
            data = hdr_read_volume(header_data);
            
        case PTKImageFileFormat.Gipl
            header_data = gipl_read_header(header_filename);
            data = gipl_read_volume(header_data);
            
        case PTKImageFileFormat.Isi
            header_data = isi_read_header(header_filename);
            data = isi_read_volume(header_data);

        case PTKImageFileFormat.Nifti
            header_data = nii_read_header(header_filename);
            data = nii_read_volume(header_data);

        case PTKImageFileFormat.V3d
            header_data = v3d_read_header(header_filename);
            data = v3d_read_volume(header_data);

        case PTKImageFileFormat.Vmp
            header_data = hdr_read_header(header_filename);
            data = hdr_read_volume(header_data);

        case PTKImageFileFormat.V3d
            header_data = v3d_read_header(header_filename);
            data = v3d_read_volume(header_data);

        case PTKImageFileFormat.Vmp
            header_data = vmp_read_header(header_filename);
            data = vmp_read_volume(header_data);

        case PTKImageFileFormat.Xif
            header_data = xif_read_header(header_filename);
            data = xif_read_volume(header_data);

        case PTKImageFileFormat.Vtk
            header_data = vtk_read_header(header_filename);
            data = vtk_read_volume(header_data);

        case PTKImageFileFormat.MicroCT
            header_data = vff_read_header(header_filename);
            data = vff_read_volume(header_data);

        case PTKImageFileFormat.Par
            header_data = par_read_header(header_filename);
            data = par_read_volume(header_data);            
    end
    
    if isempty(header_data)
        reporting.Error('PTKLoadOtherFormat:MetaHeaderReadFailed', ['Unable to read metaheader data from ' header_filename]);
    end
    
    new_dimension_order = [1, 2, 3];
    flip_orientation = [false, false, false];
    
%     if isfield(header_data, 'TransformMatrix')
%         transform_matrix = str2num(header_data.TransformMatrix); %#ok<ST2NM>
%         [new_dimension_order, flip_orientation] = PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromMhdCosines(transform_matrix(1:3), transform_matrix(4:6), transform_matrix(7:9), reporting);
%     else        
%         [new_dimension_order, flip_orientation] = PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromAnatomicalOrientation(header_data.AnatomicalOrientation, reporting);
%     end
% 
    image_dims = header_data.Dimensions(1:3);
    voxel_size = header_data.PixelDimensions(1:3);

%     if strcmp(header_data.ElementType,'MET_UCHAR')
%         data_type = 'uint8';
%     elseif strcmp(header_data.ElementType,'MET_CHAR')
%         data_type = 'int8';
%     elseif strcmp(header_data.ElementType,'MET_SHORT')
%         data_type = 'int16';
%     elseif strcmp(header_data.ElementType,'MET_USHORT')
%         data_type = 'uint16';
%     elseif strcmp(header_data.ElementType,'MET_INT')
%         data_type = 'int32';
%     elseif strcmp(header_data.ElementType,'MET_UINT')
%         data_type = 'uint32';
%     elseif strcmp(header_data.ElementType,'MET_FLOAT')
%         data_type = 'single';
%     elseif strcmp(header_data.ElementType,'MET_DOUBLE')
%         data_type = 'double';
%     else
%         data_type = 'uint16';
%     end
% 
% 
    data_type = class(data);
    original_image = zeros(image_dims, data_type);
    original_image(:) = cast(data(:), data_type);

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

    reporting.ShowWarning('PTKLoadOtherFormat:AssumedCT', 'No modality information - I am assuming these images are CT with slope 1 and intercept 0.', []);
    
    % Guess that images with some strongly negative values are from CT images while
    % others are MR
    min_value = min(original_image(:));
    if (min_value < -500)
        modality = 'CT';
    elseif (min_value >= 0)
        modality = 'MR';
    end

    ptk_image = PTKDicomImage(original_image, rescale_slope, rescale_intercept, voxel_size, modality, study_uid, header_data);
    ptk_image.Title = filenames{1};
end