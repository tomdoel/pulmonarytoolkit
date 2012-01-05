function image_info = TDChooseImagingFiles(image_path)
    % TDChooseImagingFiles. Displays a dialog for choosing image files to load.
    %
    %     This function displays a dialog which allows users to select medical
    %     imaging files to load. The function returns a TDImageInfo structure
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
    
    [image_path, filenames, filter_index] = TDDiskUtilities.ChooseFiles('Select the file to import', image_path, true, filespec);
    
    if isempty(image_path)
        image_info = [];
        return
    end
    
    % If in DICOM format, then we will load the entire directory
    if (filter_index ==  1)
        filenames = TDTextUtilities.SortFilenames(TDDiskUtilities.GetDirectoryFileList(image_path, '*'));
        image_type = TDImageFileFormat.Dicom;
    elseif (filter_index ==  2)
        image_type = TDImageFileFormat.Metaheader;
    end
    
    [~, name, ext] = fileparts(filenames{1});
    if strcmp(ext, '.mat')
        image_type = TDImageFileFormat.Matlab;
    elseif strcmp(ext, '.mhd') || strcmp(ext, '.mha')
        image_type = TDImageFileFormat.Metaheader;
        
    % If a .raw file is selected, look for the corresponding .mha or .mhd file
    elseif strcmp(ext, '.raw')
        if exist(fullfile(image_path, [name '.mha']), 'file')
            filename = [name '.mha'];
            filenames = {filename};
            image_type = TDImageFileFormat.Metaheader;
        elseif exist(fullfile(image_path, [name '.mhd']), 'file')
            filename = [name '.mhd'];
            filenames = {filename};
            image_type = TDImageFileFormat.Metaheader;
        end
    end
    image_info = TDImageInfo(image_path, filenames, image_type, [], [], []);
end
