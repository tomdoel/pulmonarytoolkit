function loaded_image = MimLoadImageFromDicomFiles(image_path, filenames, reporting)
    % Load a series of DICOM files into a 3D volume
    %
    % Syntax:
    %     loaded_image = MimLoadImageFromDicomFiles(image_path, filenames, reporting);
    %
    % Parameters:
    %     image_path: location of the DICOM files to load
    %     filenames: a filename string, or cell array of filenames
    %     reporting (Optional[CoreReportingInterface]): object
    %         for reporting progress and warnings
    %
    % Returns:
    %     loaded_image (PTKImage): a PTKImage containing the 3D volume
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    % Create a reporting object if none was provided
    if nargin < 3
        reporting = CoreReportingDefault();
    end
    
    % A single filename canbe specified as a string
    if ischar(filenames)
        filenames = {filenames};
    end
    
    dicomLibrary = DMFallbackDicomLibrary.getLibrary();
    
    [image_volume_wrapper, representative_metadata, slice_thickness, global_origin_mm] = DMLoadMainImageFromDicomFiles(image_path, filenames, dicomLibrary, reporting);
    
    if ~isempty(representative_metadata) && isfield(representative_metadata, 'Modality') && ~isempty(representative_metadata.Modality)
        if ~MimModalityIsSupported(representative_metadata.Modality)
            reporting.Error('MimLoadImageFromDicomFiles:ModalityNotSupported', ['The ' representative_metadata.Modality ' modality is not supported']);
        end
    end
    
    if isempty(image_volume_wrapper.RawImage)
        reporting.Error('MimLoadImageFromDicomFiles:NoPixelData', 'The DICOM file contains no pixel data');
    end
    
    if isempty(slice_thickness)
        reporting.ShowWarning('MimLoadImageFromDicomFiles:NoSliceThickness', 'No information found about the slice thickness. Arbitrarily setting slice thickness to 1');
        slice_thickness = 1;
    end
    
    % Detect and remove padding values
    padding_value = MimRemovePaddingValues(image_volume_wrapper, representative_metadata, reporting);
    
    % Construct a PTKDicomImage from the loaded image volume
    loaded_image = PTKDicomImage.CreateDicomImageFromMetadata(image_volume_wrapper, representative_metadata, slice_thickness, global_origin_mm, padding_value, reporting);
    
end
