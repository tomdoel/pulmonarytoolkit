function PTKSaveAsMatlab(image_data, path, filename, reporting)
    % PTKSaveAsMatlab. Saves an image as a Matlab matrix
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveAsMatlab(image_data, path, filename, reporting)
    %
    %             image_data      is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             reporting       an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %            
    
    if ~isa(image_data, 'PTKImage')
        reporting.Error('PTKSaveAsMatlab:InputMustBePTKImage', 'Requires a PTKImage as input');
    end

    value = image_data.RawImage; %#ok<NASGU>
    full_filename = fullfile(path, filename);
    MimDiskUtilities.Save(full_filename, value);
end
