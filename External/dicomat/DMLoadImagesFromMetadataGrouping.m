function imageWrapper = DMLoadImagesFromMetadataGrouping(metadataGrouping, dicomLibrary, reporting)
    % Loads metadata from a series of DICOM files
    %
    % Syntax:
    %     image_volume = DMLoadImagesFromMetadataGrouping(metadata_list, reporting)
    %
    % Parameters:
    %     imageWrapper: a CoreWrapper object containing the image volume     
    %
    %     metadataGrouping: a DMFileGrouping containing metadata
    %
    %     dicomLibrary: (Optional) An object implementing DMDicomLibraryInterface
    %
    %     reporting:      (Optional) A CoreReporting or other implementor of CoreReportingInterface,
    %                     for error and progress reporting. Create a CoreReporting
    %                     with no arguments to hide all reporting. If no
    %                     reporting object is specified then a default
    %                     reporting object with progress dialog is created
    %
    %
    % .. Licence
    %    -------
    %    Part of DicoMat. https://github.com/tomdoel/dicomat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %

    if nargin < 3
        reporting = CoreReportingDefault();
    end
    
    if nargin < 2
        dicomLibrary = DMDicomLibrary.getLibrary;
    end
    
    reporting.ShowProgress('Reading pixel data');
    reporting.UpdateProgressValue(0);

    imageWrapper = CoreWrapper();
    
    num_slices = length(metadataGrouping.Metadata);

    % Load image slice
    first_image_slice = dicomLibrary.dicomread(metadataGrouping.Metadata{1});
    if isempty(first_image_slice)
        return;
    end

    % Pre-allocate image matrix
    size_i = metadataGrouping.Metadata{1}.Rows;
    size_j = metadataGrouping.Metadata{1}.Columns;
    size_k = num_slices;
    samples_per_pixel = metadataGrouping.Metadata{1}.SamplesPerPixel;
    
    % Pre-allocate image matrix
    data_type = whos('first_image_slice');
    data_type_class = data_type.class;
    if (strcmp(data_type_class, 'char'))
        reporting.ShowMessage('DMLoadImagesFromMetadataGrouping:SettingDatatypeToInt8', 'Char datatype detected. Setting to int8');
        data_type_class = 'int8';
    end
    imageWrapper.RawImage = zeros([size_i, size_j, size_k, samples_per_pixel], data_type_class);
    imageWrapper.RawImage(:, :, 1, :) = first_image_slice;
    
    for file_index = 2 : num_slices
        imageWrapper.RawImage(:, :, file_index, :) = dicomLibrary.dicomread(metadataGrouping.Metadata{file_index});
        reporting.UpdateProgressValue(round(100*(file_index)/num_slices));
    end
    
    reporting.CompleteProgress();
end