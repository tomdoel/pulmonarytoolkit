function image = MimLoadImageFromMatlabFiles(path, filenames, reporting)
    % MimLoadImageFromMatlabFiles. Loads a 3D image volume from a Matlab file
    %
    %    This function is used to load raw image data saved in a Matlab matrix
    %
    %     Syntax
    %     ------
    %
    %         loaded_image = MimLoadImageFromMatlabFiles(path, filenames, reporting)
    %
    %             loaded_image    a PTKImage containing the 3D volume
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             reporting (optional) - an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    full_path = fullfile(path, filenames{1});
    image_struct = load(full_path);
    image = image_struct.image;
    
    