function dicom_image = PTKLoad3DRawAndMetaFiles(path, filenames, study_uid, reporting)
    % PTKLoad3DRawAndMetaFiles. Reads images from raw and meteheader files and returns as a PTKImage.
    %
    %     Note: Currently assumes that images are CT
    %
    %     Syntax
    %     ------
    %
    %         dicom_image = PTKLoad3DRawAndMetaFiles(image_data, path, filename, data_type, reporting)
    %
    %             dicom_image     is a PTKDicomImage class containing the image
    %             path            The path where the files are located. For the
    %                             current directory, use .
    %             filenames       can be a single string containspecify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             reporting       Optional - an object implementing the PTKReporting 
    %                             interface for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    if nargin < 4
        reporting = PTKReportingDefault;
    end
    
    if nargin < 2
        reporting.Error('PTKLoad3DRawAndMetaFiles:NotEnoughArguments', 'PTKLoad3DRawAndMetaFiles requires a minimum of two arguments: the current path and  list of filenames');
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
    [pathstr, ~, ~] = fileparts(header_filename);

    header_data = PTKDiskUtilities.ReadMetaHeader(header_filename);
    if isempty(header_data)
        reporting.Error('PTKLoad3DRawAndMetaFiles:MetaHeaderReadFailed', ['Unable to read metaheader data from ' header_filename]);
    end
    
    if strcmp(header_data.AnatomicalOrientation, 'RPI')
        new_dimension_order = [2 1 3];
        flip_orientation = [0 0 0];
    elseif strcmp(header_data.AnatomicalOrientation, 'RPS')
        new_dimension_order = [2 1 3];
        flip_orientation = [0 0 1];
    elseif strcmp(header_data.AnatomicalOrientation, 'RAI')
        new_dimension_order = [2 1 3];
        flip_orientation = [0 0 1];
    elseif strcmp(header_data.AnatomicalOrientation, 'IPR')
        new_dimension_order = [3 1 2];
        flip_orientation = [0 0 0];
    else
        reporting.Error('PTKLoad3DRawAndMetaFiles:UnsupportedOrientation', ['PTKLoad3DRawAndMetaFiles: WARNING: no implementation yet for anatomical orientation ' header_data.AnatomicalOrientation '.']);
    end
        
    image_dims = sscanf(header_data.DimSize, '%d %d %d');
    
    % Note: for voxel size, we have a choice of ElementSpacing or ElementSize
    % We choose ElementSpacing as we assume all the voxels are contiguous
    voxel_size = sscanf(header_data.ElementSpacing, '%f %f %f');    
    voxel_size = voxel_size(new_dimension_order)';
    
    if strcmp(header_data.ElementType,'MET_UCHAR')
        data_type = 'uint8';
    elseif strcmp(header_data.ElementType,'MET_SHORT')
        data_type = 'int16';
    else
        data_type = 'uint16';
    end

    raw_image_filename = fullfile(pathstr, header_data.ElementDataFile);

    % Read in the raw image file
    file_id = fopen(raw_image_filename);
    if file_id <= 0
        reporting.Error('PTKLoad3DRawAndMetaFiles:OpenFileFailed', ['Unable to open file ' raw_image_filename]);
    end
    original_image = zeros(image_dims', data_type);
    z_length = image_dims(3);
    for z_index = 1 : z_length
        if exist('reporting', 'var')
            reporting.UpdateProgressValue(round(100*(z_index-1)/z_length));
        end
        
        original_image(:,:,z_index) = cast(fread(file_id, image_dims(1:2)', data_type), data_type);
    end
    fclose(file_id);
    
    reporting.UpdateProgressAndMessage(0, 'Reslicing');

    if ~isequal(new_dimension_order, [1, 2, 3])
        original_image = permute(original_image, new_dimension_order);
    end
    if flip_orientation(1)
        original_image = original_image(end:-1:1, :, :);
    end
    if flip_orientation(2)
        original_image = original_image(:, end:-1:1, :);
    end
    if flip_orientation(3)
        original_image = original_image(:, :, end:-1:1);
    end
    
    rescale_slope = int16(1);
    rescale_intercept = int16(0);

    reporting.ShowWarning('PTKLoad3DRawAndMetaFiles:AssumedCT', 'No modality information - I am assuming these images are CT with slope 1 and intercept 0.', []);
    modality = 'CT';
    dicom_image = PTKDicomImage(original_image, rescale_slope, rescale_intercept, voxel_size, modality, study_uid, header_data);
    dicom_image.Title = filenames{1};


