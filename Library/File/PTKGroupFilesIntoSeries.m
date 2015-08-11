function grouper = PTKGroupFilesIntoSeries(filename, reporting)
    % PTKGroupFilesIntoSeries.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    reporting.ShowProgress('Imorting data');
    tags_to_get = DMDicomDictionary.GroupingDictionary;
    
    [import_folder, filename_only] = CoreDiskUtilities.GetFullFileParts(filename);
    grouper = PTKFileSeriesGrouper;
    
    % Find out file type. 0=does not exist; 2=file; 7-directory
    exist_result = exist(filename, 'file');
    
    % For a directory, we import every file
    if exist_result == 7
        GroupDirectoryRecursive(grouper, import_folder, tags_to_get, reporting);
        
        % For a single file, we check if it is Dicom. If so, we import the whole
        % folder. Otherwise we only import the file
    elseif exist_result == 2
        uid = GetUid(import_folder, filename_only, tags_to_get);
        if isempty(uid)
            GroupFileWithUid(grouper, import_folder, filename_only, uid);
        else
            GroupDirectoryRecursive(grouper, import_folder, tags_to_get, reporting);
        end
    else
        reporting.Error('PTKGroupFilesIntoSeries:FileDoesNotExist', ['The file or directory ' filename ' does not exist.']);
    end
    
    reporting.CompleteProgress;
end

function uid = GetUid(folder, filename, tags_to_get)
    full_file_name = fullfile(folder, filename);
    uid = PTKDicomUtilities.GetDicomSeriesUid(full_file_name, tags_to_get);
end

function GroupFile(grouper, folder, filename, tags_to_get, reporting)
    uid = GetUid(folder, filename, tags_to_get);
    full_filename = PTKFilename(folder, filename);
    grouper.AddFile(uid, full_filename);
end

function GroupFileWithUid(grouper, folder, filename, uid)
    full_filename = PTKFilename(folder, filename);
    grouper.AddFile(uid, full_filename);
end

function GroupDirectoryRecursive(grouper, import_folder, tags_to_get, reporting)
    
    directories_to_do = CoreStack(import_folder);
    
    while ~directories_to_do.IsEmpty
        current_dir = directories_to_do.Pop;
        
        reporting.UpdateProgressMessage(['Importing data from: ' current_dir]);
        
        if reporting.HasBeenCancelled
            reporting.Error(CoreReporting.CancelErrorId, 'User cancelled');
        end
        
        GroupFilesInDirectory(grouper, current_dir, tags_to_get, reporting);
        next_dirs = CoreDiskUtilities.GetListOfDirectories(current_dir);
        for dir_to_add = next_dirs
            new_dir = fullfile(current_dir, dir_to_add{1});
            directories_to_do.Push(new_dir);
        end
    end
end

function GroupFilesInDirectory(grouper, directory, tags_to_get, reporting)
    
    all_filenames = CoreTextUtilities.SortFilenames(CoreDiskUtilities.GetDirectoryFileList(directory, '*'));
    for filename = all_filenames
        GroupFile(grouper, directory, filename{1}, tags_to_get, reporting);
    end
end