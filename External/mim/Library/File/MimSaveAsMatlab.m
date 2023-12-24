function MimSaveAsMatlab(image_data, path, filename, reporting)
    % Save an image as a Matlab matrix
    %
    % Syntax:
    %     MimSaveAsMatlab(image_data, path, filename, reporting);
    %
    % Parameters:
    %     image_data: a PTKImage (or PTKDicomImage) class containing the image
    %                 to be saved
    %     path, filename: specify the location to save the files.
    %     reporting (CoreReportingInterface): an object
    %         for reporting progress and warnings
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %            
    
    if ~isa(image_data, 'PTKImage')
        reporting.Error('MimSaveAsMatlab:InputMustBePTKImage', 'Requires a PTKImage as input');
    end

    full_filename = fullfile(path, filename);
    value = [];
    value.image = image_data.RawImage;
    MimDiskUtilities.Save(full_filename, value);
end
