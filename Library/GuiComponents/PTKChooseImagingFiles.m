function image_info = PTKChooseImagingFiles(image_path, reporting)
    % PTKChooseImagingFiles. Displays a dialog for choosing image files to load.
    %
    %     This function displays a dialog which allows users to select medical
    %     imaging files to load. The function returns a PTKImageInfo structure
    %     which contains the filenames and paths. If a DICOM file is selected,
    %     then all matching files in that directory will be selected.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    filespec = {
        '*;*.*', 'All files (*.*)';
        '*;*.*', 'DICOM files (*.*)';
        '*.mhd;*.mha', 'Metaheader and raw data (*.mhd,*.mha)'
        };
    
    [image_path, filenames, filter_index] = PTKDiskUtilities.ChooseFiles('Select the file to import', image_path, true, filespec);
    
    if isempty(image_path)
        image_info = [];
        return
    end
    
    % If in DICOM format, then we will load the entire directory
    if (filter_index ==  2)
        filenames_dicom = PTKTextUtilities.SortFilenames(PTKDiskUtilities.GetDirectoryFileList(image_path, '*'));
        filenames_dicom = PTKDiskUtilities.RemoveNonDicomFiles(image_path, filenames_dicom);
        image_type = PTKImageFileFormat.Dicom;
        
        % If there are no valid DICOM files then we return an ImageInfo with
        % just the path and image type set
        if isempty(filenames_dicom)
            image_info = PTKImageInfo(image_path, [], image_type, [], [], []);
            return;
        end
        image_info = PTKImageInfo(image_path, filenames_dicom, image_type, [], [], []);
        return;
        
    elseif (filter_index ==  3)
        image_type = PTKImageFileFormat.Metaheader;
        image_info = PTKImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;
    end
    
    % No format specified, so we try to infer from the file itself
    [image_type, principal_filename, secondary_filenames] = PTKDiskUtilities.GuessFileType(image_path, filenames{1}, [], reporting);
    filenames = principal_filename;
    
    % If in DICOM format, then we will load the entire directory
    if (image_type == PTKImageFileFormat.Dicom)
        filenames = PTKTextUtilities.SortFilenames(PTKDiskUtilities.GetDirectoryFileList(image_path, '*'));
        filenames = PTKDiskUtilities.RemoveNonDicomFiles(image_path, filenames);
        
        % If there are no valid DICOM files then we return an ImageInfo with
        % just the path and image type set
        if isempty(filenames)
            image_info = PTKImageInfo(image_path, [], image_type, [], [], []);
            return;
        end
    end

    image_info = PTKImageInfo(image_path, filenames, image_type, [], [], []);
end


