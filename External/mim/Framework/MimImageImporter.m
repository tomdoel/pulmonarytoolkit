function uids = MimImageImporter(filename_or_root_directory, database, reporting)
    % MimImageImporter. Recrusively imports image files into a MimImageDatabase object
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    reporting.ShowProgress('Importing data');
    tags_to_get = DMDicomDictionary.GroupingDictionary;
    
    [import_folder, filename_only] = CoreDiskUtilities.GetFullFileParts(filename_or_root_directory);
    
    % Find out file type. 0=does not exist; 2=file; 7=directory
    exist_result = exist(filename_or_root_directory, 'file');
    
    if exist_result == 7
        % For a directory, we import every file
        uids = ImportDirectoryRecursive(database, import_folder, tags_to_get, reporting);
        
    elseif exist_result == 2
        % For a single file, we check if it is Dicom.
        single_image_metainfo = MimGetSingleImageInfo(import_folder, filename_only, [], tags_to_get, reporting);
        if single_image_metainfo.ImageFileFormat == MimImageFileFormat.Dicom
            % For a Dicom file we import the whole folder
            uids = ImportDirectoryRecursive(database, import_folder, tags_to_get, reporting);
        else
            % For a non-Dicom file we import only the primary file
            database.AddImage(single_image_metainfo);
            uids = {single_image_metainfo.SeriesUid};
        end
        
    else
        reporting.Error('MimImageImporter:FileDoesNotExist', ['The file or directory ' filename ' does not exist.']);
    end
    
    reporting.CompleteProgress;
end

function uids = ImportDirectoryRecursive(database, import_folder, tags_to_get, reporting)
    uids = [];
    directories_to_do = CoreStack(import_folder);
    
    while ~directories_to_do.IsEmpty
        current_dir = directories_to_do.Pop;
        
        reporting.UpdateProgressMessage(['Importing data from: ' current_dir]);
        
        if reporting.HasBeenCancelled
            reporting.Error(CoreReporting.CancelErrorId, 'User cancelled');
        end
        
        uids = [uids, ImportFilesInDirectory(database, current_dir, tags_to_get, reporting)];
        next_dirs = CoreDiskUtilities.GetListOfDirectories(current_dir);
        for dir_to_add = next_dirs
            new_dir = fullfile(current_dir, dir_to_add{1});
            directories_to_do.Push(new_dir);
        end
    end
    uids = unique(uids);
end

function uids = ImportFilesInDirectory(database, directory, tags_to_get, reporting)
    uids = [];
    all_filenames = CoreTextUtilities.SortFilenames(CoreDiskUtilities.GetDirectoryFileList(directory, '*'));
    for filename = all_filenames
        if ~strcmp(filename{1}, 'DICOMDIR')
            try
                single_image_metainfo = MimGetSingleImageInfo(directory, filename{1}, [], tags_to_get, reporting);
                if ~isempty(single_image_metainfo.ImageFileFormat)
                    database.AddImage(single_image_metainfo);
                    new_uid = single_image_metainfo.SeriesUid;
                    if ~ismember(new_uid, uids)
                        uids{end + 1} = new_uid;
                    end
                end
            catch ex
                reporting.ShowWarning('MimImageImporter:ImportFileFailed', ['Failed to import file ' filename{1} ' due to error: ' ex.message]);
            end
        end
    end
end