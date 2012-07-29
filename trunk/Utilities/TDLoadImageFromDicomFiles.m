function loaded_image = TDLoadImageFromDicomFiles(path, filenames, check_files, reporting)
    % TDLoadImageFromDicomFiles. Loads a series of DICOM files into a 3D volume
    %
    %     Syntax
    %     ------
    %
    %         loaded_image = TDLoadImageFromDicomFiles(path, filenames, reporting)
    %
    %             loaded_image    a TDImage containing the 3D volume
    %
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %
    %             check_files     Set this to true to perform additional
    %                             checking to ensure the data is loaded in the
    %                             correct order and forms a single series.
    %                             Setting to false will result in faster
    %                             loading, but assumes all files form a single
    %                             series, and also assumes that when sorted into
    %                             numerical-alphabetical order, the files are in
    %                             the correct order
    %
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
    
    reporting.ShowProgress('Loading images');
    
    filenames = TDTextUtilities.SortFilenames(filenames);
    
    
    % Load metadata and image data from first file in the list
    [metadata_first_file, first_image_slice] = ReadDicomFile(fullfile(path, filenames{1}), reporting);
    
    num_slices = length(filenames);
    size_i = metadata_first_file.Height;
    size_j = metadata_first_file.Width;
    size_k = num_slices;

    
    % Special case for a single image
    if num_slices == 1
        loaded_image = first_image_slice;
        slice_thickness = metadata_first_file.SliceThickness;        
    else
        % Pre-allocate image matrix
        data_type = whos('first_image_slice');
        data_type_class = data_type.class;
        if (strcmp(data_type_class, 'char'))
            reporting.ShowMessage('TDLoadImageFromDicomFiles:SettingDatatypeToInt8', 'TDLoadImageFromDicomFiles: char datatype detected. Setting to int8');
            data_type_class = 'int8';
        end
        loaded_image = zeros(size_i, size_j, size_k, data_type_class);
        loaded_image(:, :, 1) = first_image_slice;

        % Load metadata and image data from second file in the list
        [metadata_second_file, second_image_slice] = ReadDicomFile(fullfile(path, filenames{2}), reporting);
        loaded_image(:, :, 2) = second_image_slice;
        
        % Check that second image is from the same series
        if ~strcmp(metadata_first_file.SeriesInstanceUID, metadata_second_file.SeriesInstanceUID)
            reporting.ShowWarning('TDLoadImageFromDicomFiles:MultipleSeriesFound', 'Warning: These images are from more than one series', []);
        end

        % For the purposes of building an image volume, we take slice thickness
        % to be the spacing between adjacent slices, not the scanning slice
        % thickness (SliceThickness tag), which is different. Computing the
        % spacing using the SliceLocation tag is a more reliable 
        % measure than the SpacingBetweenSlices attribute, which may not be
        % defined.
        slice_thickness = abs(metadata_second_file.SliceLocation - metadata_first_file.SliceLocation);
        
        % If there are only 2 slices, we already have everything loaded
        if num_slices > 2
            
            % Load metadata and image data from last file in the list
            [metadata_last_file, last_image_slice] = ReadDicomFile(fullfile(path, filenames{num_slices}), reporting);
            loaded_image(:, :, size_k) = last_image_slice;
            
            % Check whether the first and last slice are from the same series. This
            % is a quick way of approximately checking if all the data is from the
            % same series. To do it properly, we need to check this for every slice.
            % We only do this if check_data is true, because processing the metadata
            % for every slice using dicominfo is very slow.
            if ~strcmp(metadata_first_file.SeriesInstanceUID, metadata_last_file.SeriesInstanceUID)
                reporting.ShowWarning('TDLoadImageFromDicomFiles:MultipleSeriesFound', 'Warning: These images are from more than one series', []);
            end
            
            distance_between_first_and_last = abs(metadata_first_file.SliceLocation - metadata_last_file.SliceLocation);
            computed_distance = (num_slices - 1)*slice_thickness;
            if abs(computed_distance - distance_between_first_and_last) > 0.1;
                disp('*variable slice thickness');
                reporting.ShowWarning('TDLoadImageFromDicomFiles:InconsistentSliceThickness', 'Warning: Not all slices have the same thickness', []);
            else
                disp('*slice thickness OK');
            end
            
            
            if check_files
                series_uids = repmat({''}, size_k, 1);
                slice_locations = zeros(size_k, 1);
                slice_locations(1) = metadata_first_file.SliceLocation;
                series_uids{1} = metadata_first_file.SeriesInstanceUID;
                slice_locations(size_k) = metadata_last_file.SliceLocation;
                series_uids{size_k} = metadata_last_file.SeriesInstanceUID;
            end
            
            % Decide the order in which to load the data
            if (metadata_first_file.SliceLocation > metadata_last_file.SliceLocation)
                file_index_range = 3 : (size_k - 1);
            else
                file_index_range = (size_k - 1) : -1 : 3;
            end
            
            % Load remaining files
            for file_number = file_index_range
                if exist('reporting', 'var')
                    reporting.UpdateProgressValue(round(100*(file_number-1)/size_k));
                end
                next_filename_or_metadata = fullfile(path, filenames{file_number});
                
                % We only load the metadata if check_files is true, because the
                % loading and processing of metadata using dicominfo is very slow
                if check_files
                    try
                        next_filename_or_metadata = dicominfo(next_filename_or_metadata);
                        slice_locations(file_number) = next_filename_or_metadata.SliceLocation;
                        series_uids{file_number} = next_filename_or_metadata.SeriesInstanceUID;
                    catch exception
                        reporting.Error('TDLoadImageFromDicomFiles:MetadataReadFailure', ['TDLoadImageFromDicomFiles: error while reading metadata from ' filenames{file_number} '. Error:' exception.message], []);
                    end
                end
                try
                    % If check_files is true, next_file will be metadata
                    % If false, next_file will be the filename
                    loaded_image(:, :, file_number) = dicomread(next_filename_or_metadata);
                catch exception
                    reporting.Error('TDLoadImageFromDicomFiles:DicomReadFailure', ['TDLoadImageFromDicomFiles: error while reading file ' filenames{file_number} '. Error:' exception.message]);
                end
            end
            
            % Perform additional sorting of files and checking they are part of the
            % same series
            if check_files
                % Reorder slices according the slice position
                if all(strcmp(series_uids, series_uids{1}))
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
            end
        end
    end
    
    % Replace padding value with zero
    if (isfield(metadata_first_file, 'PixelPaddingValue'))
        padding_value = metadata_first_file.PixelPaddingValue;
        
        padding_indices = find(loaded_image == padding_value);
        if (~isempty(padding_indices))
            reporting.ShowMessage('TDLoadImageFromDicomFiles:ReplacingPaddingValue', ['Replacing padding value ' num2str(padding_value) ' with zeros.'], []);
            loaded_image(padding_indices) = 0;
        end
    end
    
    % Check for unspecified padding value in GE images
    if strcmp(metadata_first_file.Manufacturer, 'GE MEDICAL SYSTEMS')
        extra_padding_pixels = find(loaded_image == -2000);
        if ~isempty(extra_padding_pixels) && (metadata_first_file.PixelPaddingValue ~= -2000)
            reporting.ShowWarning('TDLoadImageFromDicomFiles:IncorrectPixelPadding', 'This image is from a GE scanner and appears to have an incorrect PixelPaddingValue. This is a known issue with the some GE scanners. I am assuming the padding value is -2000 and replacing with zero.', []);
            loaded_image(extra_padding_pixels) = 0;
        end
    end
    
    loaded_image = TDDicomImage.CreateDicomImageFromMetadata(loaded_image, metadata_first_file, slice_thickness, reporting);
end

function [metadata, image_data] = ReadDicomFile(file_name, reporting)
    try
        metadata = dicominfo(file_name);
    catch exception
        reporting.Error('TDLoadImageFromDicomFiles:MetaDataReadError', ['TDLoadImageFromDicomFiles: error while reading metadata from ' file_name ': is this a DICOM file? Error:' exception.message]);
    end
    try
        image_data = dicomread(metadata);
    catch exception
        reporting.Error('TDLoadImageFromDicomFiles:DicomReadError', ['TDLoadImageFromDicomFiles: error while reading file ' file_name '. Error:' exception.message]);
    end
end