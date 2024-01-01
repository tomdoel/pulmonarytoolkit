function path_name = PTKSaveAs(image_data, patient_name, path_name, is_secondary_capture, dicom_metadata, reporting)
    % Prompts the user for a filename and file type, and saves the image
    %
    % Syntax: 
    %     PTKSaveAs(image_data, patient_name, path_name, is_secondary_capture, dicom_metadata, reporting)
    %
    % Parameters:
    %     image_data: a PTKImage (or PTKDicomImage) class containing the image
    %         to be saved
    %     patient_name: specifies the patient name to be stored in the image (only
    %         used when there is no metadata available in the image)
    %     path_name: specify the location to save the DICOM data. One 2D file
    %         will be created for each image slice in the z direction. 
    %         Each file is numbered, starting from 0.
    %         So if filename is 'MyImage.DCM' then the files will be
    %         'MyImage0.DCM', 'MyImage1.DCM', etc.
    %     is_secondary_capture: true if the image is derived, false if the pixel data 
    %         directly corresponds to the original image pixel data
    %     dicom_metadata: a structure containing additional manufacturer tags
    %         used to construct Dicom images
    %     reporting (CoreReportingInterface): object for reporting progress and warnings
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %  
    
    if ~isa(image_data, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if nargin < 4 || isempty(is_secondary_capture)
        is_secondary_capture = false;
    end
    
    if nargin < 5 || isempty(dicom_metadata)
        dicom_metadata = PTKDicomMetadata();
    end
    
    if nargin < 6
        reporting = CoreReportingDefault();
    end
    
    path_name = MimSaveAs(image_data, patient_name, path_name, is_secondary_capture, dicom_metadata, reporting);
end
