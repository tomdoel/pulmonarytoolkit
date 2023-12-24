function image = MimLoadImageFromMatlabFiles(path, filenames, reporting)
    % Load a 3D image volume from a Matlab file
    %
    % This function is used to load raw image data saved in a Matlab matrix
    %
    % Syntax:
    %     loaded_image = MimLoadImageFromMatlabFiles(path, filenames, reporting)
    %
    % Parameters:
    %     path: specify the location to save the DICOM data. One 2D file
    %     filename: prefix for the filename. One 2D file
    %         will be created for each image slice in the z direction. 
    %         Each file is numbered, starting from 0.
    %         So if filename is 'MyImage.DCM' then the files will be
    %         'MyImage0.DCM', 'MyImage1.DCM', etc.
    %     reporting (Optional[CoreReportingInterface]): object
    %         for reporting progress and warnings
    %
    % Returns:
    %     loaded_image (PTKImage): image containing the 3D volume
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %        
    
    full_path = fullfile(path, filenames{1});
    image_struct = load(full_path);
    image = image_struct.image;
