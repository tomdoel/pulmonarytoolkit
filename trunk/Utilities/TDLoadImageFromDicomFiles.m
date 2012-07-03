function loaded_image = TDLoadImageFromDicomFiles(path, filenames, reporting)
    % TDLoadImageFromDicomFiles. Loads a series of DICOM files into a 3D volume
    %
    %     Syntax
    %     ------
    %
    %         loaded_image = TDLoadImageFromDicomFiles(path, filenames, reporting)
    %
    %             loaded_image    a TDImage containing the 3D volume
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             reporting       A TDReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a TDReporting
    %                             with no arguments to hide all reporting. If no
    %                             reporting object is specified then a default
    %                             reporting object with progress dialog is
    %                             created
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    if nargin < 3
        reporting = TDReportingDefault;
    end
    
    % Load first file, and use datatype to initialise the data structure
    try
        metadata = dicominfo(fullfile(path, filenames{1}));
    catch exception
        reporting.Error('TDLoadImageFromDicomFiles:MetaDataReadError', ['TDLoadImageFromDicomFiles: error while reading metadata from ' filenames{1} ': is this a DICOM file? Error:' exception.message]);
    end
    try
        first_image_slice = dicomread(metadata);
    catch exception
        reporting.Error('TDLoadImageFromDicomFiles:DicomReadError', ['TDLoadImageFromDicomFiles: error while reading file ' filenames{1} '. Error:' exception.message]);
    end
    
    if exist('reporting', 'var')
        reporting.ShowProgress('Loading images');
    end
    size_i = metadata.Height;
    size_j = metadata.Width;
    size_k = length(filenames);
    series_uids = repmat({''}, size_k, 1);
    slice_locations = zeros(size_k, 1);

    data_type = whos('first_image_slice');
    data_type_class = data_type.class;
    if (strcmp(data_type_class, 'char'))
        reporting.ShowMessage('TDLoadImageFromDicomFiles: char datatype detected. Setting to int8');
        data_type_class = 'int8';
    end
    loaded_image = zeros(size_i, size_j, size_k, data_type_class);
    loaded_image(:, :, 1) = first_image_slice;
    slice_locations(1) = metadata.SliceLocation;
    series_uids{1} = metadata.SeriesInstanceUID;
    
    % Load remaining files
    for file_number = 2 : size_k
        if exist('reporting', 'var')
            reporting.UpdateProgressValue(round(100*(file_number-1)/size_k));
        end

        try
            next_metadata = dicominfo(fullfile(path, filenames{file_number}));
            slice_locations(file_number) = next_metadata.SliceLocation;
            series_uids{file_number} = next_metadata.SeriesInstanceUID;
        catch exception
            reporting.Error('TDLoadImageFromDicomFiles:MetadataReadFailure', ['TDLoadImageFromDicomFiles: error while reading metadata from ' filenames{file_number} '. Error:' exception.message], []);
        end
        try
            loaded_image(:, :, file_number) = dicomread(next_metadata);
        catch exception
            calback.Error('TDLoadImageFromDicomFiles:DicomReadFailure', ['TDLoadImageFromDicomFiles: error while reading file ' filenames{file_number} '. Error:' exception.message]);
        end     
    end

    % Reorder slices according the slice position
    if all(strcmp(series_uids, series_uids{1}))
        %if (metadata.PatientPosition(1) == 'H')
        %    sort_mode = 'ascend';
        %elseif (metadata.PatientPosition(1) == 'F')
        %    sort_mode = 'descend';
        %else
        %    error('Unknown patient position');
        %end
        
        % All sorting is by slice location, so the patient positon shoudln't make a difference (?)
        sort_mode = 'descend';
        
        [sorted_slice_locations, index_matrix] = sort(slice_locations, sort_mode);
        slice_thicknesses = abs(sorted_slice_locations(2:end) - sorted_slice_locations(1:end-1));
        slice_thickness = slice_thicknesses(1);
        if ~all(slice_thicknesses == slice_thickness)
            reporting.ShowWarning('TDLoadImageFromDicomFiles:InconsistentSliceThickness', 'Warning: Not all slices have the same thickness', []);
        end
        loaded_image(:,:,:) = loaded_image(:,:,index_matrix);
    else
        reporting.ShowWarning('TDLoadImageFromDicomFiles:MultipleSeriesFound', 'Warning: These images are from more than one series', []);
    end
    
    % Replace padding value with zero
    if (isfield(metadata, 'PixelPaddingValue'))
        padding_value = metadata.PixelPaddingValue;

        padding_indices = find(loaded_image == padding_value);
        if (~isempty(padding_indices))
            reporting.ShowWarning('TDLoadImageFromDicomFiles:ReplacingPaddingValue', ['Warning: Replacing padding value ' num2str(padding_value) ' with zeros.'], []);
            loaded_image(padding_indices) = 0;
        end
    end
    
    % Check for unspecified padding value in GE images
    if strcmp(metadata.Manufacturer, 'GE MEDICAL SYSTEMS')
        extra_padding_pixels = find(loaded_image == -2000);
        if ~isempty(extra_padding_pixels) && (metadata.PixelPaddingValue ~= -2000)
            reporting.ShowWarning('TDLoadImageFromDicomFiles:IncorrectPixelPadding', 'Warning: This image is from a GE scanner and appears to have an incorrect PixelPaddingValue. This is a known issue with the some GE scanners. I am assuming the padding value is -2000 and replacing with zero.', []);
            loaded_image(extra_padding_pixels) = 0;
        end
    end
    
    loaded_image = TDDicomImage.CreateDicomImageFromMetadata(loaded_image, metadata, slice_thickness, reporting);
end