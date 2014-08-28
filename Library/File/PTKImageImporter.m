function uids = PTKImageImporter(filename_or_root_directory, database, reporting)
    % PTKImageImporter. Recrusively imports image files into a PTKImageDatabase
    % object
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    reporting.ShowProgress('Importing data');
    tags_to_get = PTKDicomDictionary.GroupingTagsDictionary(false);
    
    [import_folder, filename_only] = PTKDiskUtilities.GetFullFileParts(filename_or_root_directory);
    
    % Find out file type. 0=does not exist; 2=file; 7=directory
    exist_result = exist(filename_or_root_directory, 'file');
    
    if exist_result == 7
        % For a directory, we import every file
        uids = ImportDirectoryRecursive(database, import_folder, tags_to_get, reporting);
        
    elseif exist_result == 2
        % For a single file, we check if it is Dicom.
        single_image_metainfo = PTKGetSingleImageInfo(import_folder, filename_only, tags_to_get, reporting);
        if single_image_metainfo.ImageFileFormat == PTKImageFileFormat.Dicom
            % For a Dicom file we import the whole folder
            uids = ImportDirectoryRecursive(database, import_folder, tags_to_get, reporting);
        else
            % For a non-Dicom file we import only the primary file
            database.AddImage(single_image_metainfo);
            uids = {single_image_metainfo.SeriesUid};
        end
        
    else
        reporting.Error('PTKImageImporter:FileDoesNotExist', ['The file or directory ' filename ' does not exist.']);
    end
    
    reporting.CompleteProgress;
end

function uids = ImportDirectoryRecursive(database, import_folder, tags_to_get, reporting)
    uids = [];
    directories_to_do = PTKStack(import_folder);
    
    while ~directories_to_do.IsEmpty
        current_dir = directories_to_do.Pop;
        
        reporting.UpdateProgressMessage(['Importing data from: ' current_dir]);
        
        if reporting.HasBeenCancelled
            reporting.Error(PTKSoftwareInfo.CancelErrorId, 'User cancelled');
        end
        
        uids = [uids, ImportFilesInDirectory(database, current_dir, tags_to_get, reporting)];
        next_dirs = PTKDiskUtilities.GetListOfDirectories(current_dir);
        for dir_to_add = next_dirs
            new_dir = fullfile(current_dir, dir_to_add{1});
            directories_to_do.Push(new_dir);
        end
    end
    uids = unique(uids);
end

function uids = ImportFilesInDirectory(database, directory, tags_to_get, reporting)
    uids = [];
    all_filenames = PTKTextUtilities.SortFilenames(PTKDiskUtilities.GetDirectoryFileList(directory, '*'));
    for filename = all_filenames
        if ~strcmp(filename{1}, 'DICOMDIR')
            single_image_metainfo = PTKGetSingleImageInfo(directory, filename{1}, tags_to_get, reporting);
            if ~isempty(single_image_metainfo.ImageFileFormat)
                database.AddImage(single_image_metainfo);
                new_uid = single_image_metainfo.SeriesUid;
                if ~ismember(new_uid, uids)
                    uids{end + 1} = new_uid;
                end
            end
        end
    end
end