function loaded_image = PTKLoadImageFromDicomFiles(image_path, filenames, reporting)
    % PTKLoadImageFromDicomFiles. Loads a series of DICOM files into a 3D volume
    %
    %     Syntax
    %     ------
    %
    %         loaded_image = PTKLoadImageFromDicomFiles(image_path, filenames, reporting)
    %
    %             loaded_image    a PTKImage containing the 3D volume
    %
    %             path, filename  specify the location of the DICOM files to
    %                             load
    %
    %             reporting       A PTKReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting. If no
    %                             reporting object is specified then a default
    %                             reporting object with progress dialog is
    %                             created
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    % Create a reporting object if none was provided
    if nargin < 3
        reporting = CoreReportingDefault;
    end
    
    dicomLibrary = DMFallbackDicomLibrary.getLibrary;
    
    [image_volume_wrapper, representative_metadata, slice_thickness, global_origin_mm] = DMLoadMainImageFromDicomFiles(image_path, filenames, dicomLibrary, reporting);
    
    if ~isempty(representative_metadata) && isfield(representative_metadata, 'Modality') && ~isempty(representative_metadata.Modality)
        if ~PTKModalityIsSupported(representative_metadata.Modality)
            reporting.Error('PTKLoadImageFromDicomFiles:ModalityNotSupported', ['PTK does not support the ' representative_metadata.Modality ' modality']);
        end
    end
    
    if isempty(image_volume_wrapper.RawImage)
        reporting.Error('PTKLoadImageFromDicomFiles:NoPixelData', 'The DICOM file contains no pixel data');
    end
    
    if isempty(slice_thickness)
        reporting.ShowWarning('PTKLoadImageFromDicomFiles:NoSliceThickness', 'No information found about the slice thickness. Arbitrarily setting slice thickness to 1');
        slice_thickness = 1;
    end
    
    % Detect and remove padding values
    PTKRemovePaddingValues(image_volume_wrapper, representative_metadata, reporting);
    
    % Construct a PTKDicomImage from the loaded image volume
    loaded_image = PTKDicomImage.CreateDicomImageFromMetadata(image_volume_wrapper, representative_metadata, slice_thickness, global_origin_mm, reporting);
    
end