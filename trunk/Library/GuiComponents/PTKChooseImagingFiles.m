function image_info = PTKChooseImagingFiles(image_path)
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
        '*.*', 'DICOM files (*.*)';
        '*.mhd;*.mha', 'Metaheader and raw data (*.mhd,*.mha)'
        };
    
    [image_path, filenames, filter_index] = PTKDiskUtilities.ChooseFiles('Select the file to import', image_path, true, filespec);
    
    if isempty(image_path)
        image_info = [];
        return
    end
    
    % If in DICOM format, then we will load the entire directory
    if (filter_index ==  1)
        filenames = PTKTextUtilities.SortFilenames(PTKDiskUtilities.GetDirectoryFileList(image_path, '*'));
        filenames = PTKDiskUtilities.RemoveNonDicomFiles(image_path, filenames);
        image_type = PTKImageFileFormat.Dicom;
        
        % If there are no valid DICOM files then we return an ImageInfo with
        % just the path and image type set
        if isempty(filenames)
            image_info = PTKImageInfo(image_path, [], image_type, [], [], []);
            return;
        end
    elseif (filter_index ==  2)
        image_type = PTKImageFileFormat.Metaheader;
    end
    
    [~, name, ext] = fileparts(filenames{1});
    if strcmp(ext, '.mat')
        image_type = PTKImageFileFormat.Matlab;
    elseif strcmp(ext, '.mhd') || strcmp(ext, '.mha')
        image_type = PTKImageFileFormat.Metaheader;
        
    % If a .raw file is selected, look for the corresponding .mha or .mhd file
    elseif strcmp(ext, '.raw')
        if exist(fullfile(image_path, [name '.mha']), 'file')
            filename = [name '.mha'];
            filenames = {filename};
            image_type = PTKImageFileFormat.Metaheader;
        elseif exist(fullfile(image_path, [name '.mhd']), 'file')
            filename = [name '.mhd'];
            filenames = {filename};
            image_type = PTKImageFileFormat.Metaheader;
        end
    end
    image_info = PTKImageInfo(image_path, filenames, image_type, [], [], []);
end


