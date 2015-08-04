function [loaded_image, ] = PTKLoadImageFromDicomFiles(image_path, filenames, reporting)
    % PTKLoadImageFromDicomFiles. Loads a series of DICOM files into a 3D volume
    %
    %     Syntax
    %     ------
    %
    %         loaded_image = PTKLoadImageFromDicomFiles(path, filenames, reporting)
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
    
    dicomLibrary = PTKDicomFallbackLibrary.getLibrary;
    
    [image_volume_wrapper, representative_metadata] = DMLoadMainImageFromDicomFiles(imagePath, filenames, dicomLibrary, reporting);
    
    % Detect and remove padding values
    PTKRemovePaddingValues(image_volume_wrapper, representative_metadata, reporting);
    
    % Construct a PTKDicomImage from the loaded image volume
    loaded_image = PTKDicomImage.CreateDicomImageFromMetadata(image_volume_wrapper, representative_metadata, slice_thickness, global_origin_mm, reporting);
    
end