function loaded_image = PTKLoadImageFromAnalyzeFiles(path, filenames)
    % PTKLoadImageFromAnalyzeFiles. Loads a 3D image volume from analyze files
    %
    %     Syntax
    %     ------
    %
    %         loaded_image = PTKLoadImageFromAnalyzeFiles(path, filenames, reporting)
    %
    %             loaded_image    a PTKImage containing the 3D volume
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    

    loaded_image = analyze75read(fullfile(path, filenames{1}));
    