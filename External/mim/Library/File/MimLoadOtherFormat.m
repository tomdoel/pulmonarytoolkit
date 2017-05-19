function ptk_image = MimLoadOtherFormat(path, filenames, study_uid, image_file_format, reporting)
    % MimLoadOtherFormat. Reads images from various_formats returns as a PTKImage.
    %
    %     Note: Currently assumes that images are CT
    %
    %     Syntax
    %     ------
    %
    %         ptk_image = MimLoadOtherFormat(path, filenames, study_uid, reporting)
    %
    %             ptk_image     is a PTKDicomImage class containing the image
    %             path            The path where the files are located. For the
    %                             current directory, use .
    %             filenames       the filename of the header file to load.
    %             image_file_format   enumeration of MimImageFileFormat
    %                                 describing the file format
    %             reporting (optional) - an object implementing CoreReportingInterface
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
        reporting = CoreReportingDefault;
    end
    
    if nargin < 2
        reporting.Error('MimLoadOtherFormat:NotEnoughArguments', 'MimLoadOtherFormat requires a minimum of two arguments: the current path and  list of filenames');
    end

    % If a single file has been specified, put it into an array for consistency
    % with multiple filename syntax
    if ischar(filenames)
        filenames = {filenames};
    end

    if isa(filenames, 'CoreFilename')
        path = filenames.Path;
        filenames = filenames.Name;
    elseif isa(filenames{1}, 'CoreFilename')
        path = filenames{1}.Path;
        filenames = filenames{1}.Name;
    end
    
    if nargin < 3
        reporting.ShowWarning('MimLoadOtherFormat:NoStudyUid', 'No study UID was specified - I am going to use the filename.', []);
        study_uid = filenames{1};
    end
    
    header_filename = fullfile(path, filenames{1});
    
    new_dimension_order = [1, 2, 3];
    flip_orientation = [false, false, false];
    modality = [];
    
    switch image_file_format

        case MimImageFileFormat.Nifti
            header_data = nii_read_header(header_filename);
            data = nii_read_volume(header_data);
            [new_dimension_order, flip_orientation] = MimImageCoordinateUtilities.GetDimensionPermutationVectorFromNiiOrientation(header_data, reporting);
        
        case MimImageFileFormat.Analyze % Experimental: assumes fixed orientation
            header_data = hdr_read_header(header_filename);
            data = hdr_read_volume(header_data);
            [new_dimension_order, flip_orientation] = MimImageCoordinateUtilities.GetDimensionPermutationVectorForAnalyze(header_data.Orientation, reporting);
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'Analyze file support is experimental and images may be in the wrong orientation');
            
        case MimImageFileFormat.Vtk % Experimental: assumes fixed orientation
            header_data = vtk_read_header(header_filename);
            data = vtk_read_volume(header_data);
            new_dimension_order = [1, 2, 3];
            flip_orientation = [false, false, true];
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'VTK file support is experimental and images may be in the wrong orientation');
            
        case MimImageFileFormat.Gipl % Experimental: assumes fixed orientation
            header_data = gipl_read_header(header_filename);
            data = gipl_read_volume(header_data);
            new_dimension_order = [1, 2, 3];
            flip_orientation = [false, false, true];
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'GIPL file support is experimental and images may be in the wrong orientation');
            
        case MimImageFileFormat.Isi % Experimental: assumes fixed orientation
            header_data = isi_read_header(header_filename);
            data = isi_read_volume(header_data);
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'ISI file support is experimental and images may be in the wrong orientation');

        case MimImageFileFormat.V3d % Experimental: assumes fixed orientation
            header_data = v3d_read_header(header_filename);
            data = v3d_read_volume(header_data);
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'V3D file support is experimental and images may be in the wrong orientation');

        case MimImageFileFormat.Vmp % Experimental: assumes fixed orientation
            header_data = hdr_read_header(header_filename);
            data = hdr_read_volume(header_data);
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'VMP file support is experimental and images may be in the wrong orientation');

        case MimImageFileFormat.Xif % Experimental: assumes fixed orientation
            header_data = xif_read_header(header_filename);
            data = xif_read_volume(header_data);
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'XIF file support is experimental and images may be in the wrong orientation');

        case MimImageFileFormat.MicroCT % Experimental: assumes fixed orientation
            header_data = vff_read_header(header_filename);
            data = vff_read_volume(header_data);
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'MicroCT file support is experimental and images may be in the wrong orientation');

        case MimImageFileFormat.Par % Experimental: assumes fixed orientation
            header_data = par_read_header(header_filename);
            data = par_read_volume(header_data);            
            reporting.ShowWarning('MimLoadOtherFormat:UncertainOrientation', 'PAR file support is experimental and images may be in the wrong orientation');
    end
    
    if isempty(header_data)
        reporting.Error('MimLoadOtherFormat:MetaHeaderReadFailed', ['Unable to read metaheader data from ' header_filename]);
    end
    
%     if isfield(header_data, 'TransformMatrix')
%         transform_matrix = str2num(header_data.TransformMatrix); %#ok<ST2NM>
%         [new_dimension_order, flip_orientation] = MimImageCoordinateUtilities.GetDimensionPermutationVectorFromMhdCosines(transform_matrix(1:3), transform_matrix(4:6), transform_matrix(7:9), reporting);
%     else        
%         [new_dimension_order, flip_orientation] = MimImageCoordinateUtilities.GetDimensionPermutationVectorFromAnatomicalOrientation(header_data.AnatomicalOrientation, reporting);
%     end
% 
    image_dims = header_data.Dimensions(1:3);
    voxel_size = header_data.PixelDimensions(1:3);
    voxel_size = voxel_size(:)';

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

    reporting.ShowWarning('MimLoadOtherFormat:AssumedCT', 'No modality information - I am assuming these images are CT with slope 1 and intercept 0.', []);
    
    if isempty(modality)
        % Guess that images with some strongly negative values are from CT images while
        % others are MR if all positive (note: there is no strong basis for
        % this, but it's hard to guess modality if it's not specified in
        % the header).
        min_value = min(original_image(:));
        if (min_value < -500)
            modality = 'CT';
        elseif (min_value >= 0)
            modality = 'MR';
        else
            modality = 'US';
        end
    end

    ptk_image = PTKDicomImage(original_image, rescale_slope, rescale_intercept, voxel_size, modality, study_uid, header_data);
    ptk_image.Title = filenames{1};
end