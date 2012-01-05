function TDSaveAsMatlab(image_data, path, filename, reporting)
    % TDSaveAsMatlab. Saves an image as a Matlab matrix
    %
    %     Syntax
    %     ------
    %
    %         TDSaveAsMatlab(image_data, path, filename, reporting)
    %
    %             image_data      is a TDImage (or TDDicomImage) class containing the image
    %                             to be saved
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             reporting       A TDReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a TDReporting
    %                             with no arguments to hide all reporting
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %            
    
    if ~isa(image_data, 'TDImage')
        reporting.Error('TDSaveAsMatlab:InputMustBeTDImage', 'Requires a TDImage as input');
    end

    value = image_data.RawImage; %#ok<NASGU>
    full_filename = fullfile(path, filename);
    save(full_filename, 'value');
end
