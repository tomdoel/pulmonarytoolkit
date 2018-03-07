classdef CoreDiskUtilities
    % CoreDiskUtilities. Disk-related utility functions.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    methods (Static)
        
        function exists = FileExists(path_name, filename)
            % Determine if the file exists
            
            exists = 2 == exist(fullfile(path_name, filename), 'file');
        end
        
        function exists = DirectoryExists(path_name)
            % Determine if the directory exists
            exists = 7 == exist(path_name, 'dir');
        end
        
        function RecycleFile(path_name, filename, reporting)
            % Deletes a file using the recycle bin
            
            if CoreDiskUtilities.FileExists(path_name, filename)
                
                % Switch on recycle bin before deleting
                state = recycle;
                recycle('on');
                
                full_filename = fullfile(path_name, filename);
                delete(full_filename);
                
                % Restore previous recycle bin state
                recycle(state);
            end
            
        end
        
        function BackupFile(path_name, filename, reporting)
            % Saves a backup copy of a file, ensuring it has a unique
            % filename
            
            if CoreDiskUtilities.FileExists(path_name, filename)
                new_filename = [filename '_Backup'];
                backup_number = 0;
                while CoreDiskUtilities.FileExists(path_name, new_filename)
                    backup_number = backup_number + 1;
                    new_filename = [filename '_Backup' int2str(backup_number)];                    
                end
                CoreDiskUtilities.RenameFile(path_name, filename, new_filename);                
            end
        end
        
        function renamed = RenameFile(path_name, old_filename, new_filename, reporting)
            % Renames a file
            
            if CoreDiskUtilities.FileExists(path_name, old_filename)
                source = fullfile(path_name, old_filename);
                dest = fullfile(path_name, new_filename);
                movefile(source, dest);
                renamed = true;
            else
                renamed = false;
            end
        end
        
        function home_directory = GetUserDirectory
            % Returns a path to the user's home folder
            if (ispc)
                home_directory = getenv('USERPROFILE');
            else
                home_directory = getenv('HOME');
            end
        end
        
        function [absolute_file_path, filename] = GetFullFileParts(path_or_filename)
            if exist(path_or_filename, 'dir')
                relative_pathname = path_or_filename;
                filename = '';
            else
                [relative_pathname, name, ext] = fileparts(path_or_filename);
                filename = [name ext];
            end
            
            if exist(relative_pathname, 'dir')
                current_path = pwd;
                cd(relative_pathname);
                absolute_file_path = pwd;
                cd(current_path)
            else
                absolute_file_path = fullfile(pwd, relative_pathname);
            end
        end
        
        function file_list = GetDirectoryFileList(path, filename)
            % Returns a list of files in the specified directory
            files = dir(fullfile(path, filename));
            number_files = length(files);
            file_list = {};
            for i = 1 : number_files
                filename = files(i).name;
                isdir = files(i).isdir;
                if (filename(1) ~= '.' && ~isdir)
                    file_list{end + 1} = filename; %#ok<AGROW>
                end
            end
        end
        
        function dir_list = GetListOfDirectories(path)
            % Returns a list of subdirectories in the specified directory
            
            files = dir(fullfile(path, '*'));
            number_files = length(files);
            dir_list = {};
            for i = 1 : number_files
                filename = files(i).name;
                isdir = files(i).isdir;
                if (filename(1) ~= '.' && isdir)
                    dir_list{end + 1} = filename; %#ok<AGROW>
                end
            end
        end
        
        function dir_list = GetRecursiveListOfDirectories(root_path)
            % Returns a list of all subdirectories in the specified directory, its
            % subdictories and so on
            % The list is returned as an array of CorePairs. In each CorePair, the
            % First property is the directory path (relative to the root_path
            % specified in the input parameter), and the Second property is the
            % just the name of the deepest subdirectory
            
            dirs_found = CoreStack;
            
            if ~isempty(root_path)
                dirs_to_do = CoreStack(CorePair(root_path, ''));
                while ~dirs_to_do.IsEmpty
                    next_dir = dirs_to_do.Pop;
                    dirs_found.Push(next_dir);
                    this_dir_list = CoreDiskUtilities.GetListOfDirectories(next_dir.First);
                    for index = 1 : numel(this_dir_list)
                        this_dir_list{index} = CorePair(fullfile(next_dir.First, this_dir_list{index}), this_dir_list{index});
                    end
                    dirs_to_do.Push(this_dir_list);
                end
            end
            dir_list = dirs_found.GetAndClear;
        end
        
        function OpenDirectoryWindow(directory_path)
            % Opens an explorer/finder window at the specified path
           if ispc
               
               if ~exist(directory_path, 'dir')
                   error('Directory not found');
               end
               
               dos(['explorer.exe "' directory_path '"']);
           
           elseif ismac
               unix(['Open "' directory_path '"']);
           else
               warning('CoreDiskUtilities:NotImplementedForUnix', 'Not implemented for unix');
           end
        end
        
        function [path, filenames, filter_index] = ChooseFiles(text_to_display, path, allow_multiple_files, file_spec)
            % Displays a dialog for selecting files
            
            if isempty(path)
                path = CoreDiskUtilities.GetUserDirectory;
            end
            
            if (allow_multiple_files)
                ms = 'on';
            else
                ms = 'off';
            end
            
            input_path = path;
            if (input_path(end) ~= filesep)
                input_path = [path filesep];
            end
            
            [filenames, path, filter_index] = uigetfile(file_spec, text_to_display, input_path, 'MultiSelect', ms);
            if (length(filenames) == 1) && (filenames == 0)
                path = [];
                filenames = [];
                filter_index = [];
            end
            if (~iscell(filenames))
                filenames = {filenames};
            end
        end
        
        function folder_path = ChooseDirectory(text_to_display, folder_path)
            % Displays a dialog for selecting a folder
            
            if isempty(folder_path)
                folder_path = CoreDiskUtilities.GetUserDirectory;
            end
            
            input_path = folder_path;
            if (input_path(end) ~= filesep)
                input_path = [folder_path filesep];
            end
            
            folder_path = uigetdir(input_path, text_to_display);
            
            if folder_path == 0
                folder_path = [];
            end
        end
        
        function CreateDirectoryIfNecessary(dir_name)
            if ~(exist(dir_name, 'dir') == 7)
                mkdir(dir_name);
            end
        end
        
        function CreateDirectoryAndAddPathIfNotExisting(dir_name)
            % If a directory does not exist, then create and add to the path.
            % The assumption is that if the directory already exists,
            % it is already in the path
            if ~(exist(dir_name, 'dir') == 7)
                mkdir(dir_name);
                addpath(dir_name);
            end
        end
        
        function dir = GetDirectoryForFile(filename)
            exist_result = exist(filename, 'file');
            
            if exist_result == 0
                % Directory does not exist
                error('CoreDiskUtilities:DirectoryDoesNotExist', 'The directory passed to CoreDiskUtilities.GetDirectoryForFile() does not exist.');
            
            elseif exist_result == 7
                % Directory specified
                dir = filename;
                
            elseif exist_result == 2
                % File specified - try to extract a directory
                [dir_path, ~, ~] = fileparts(filename);
                exist_result_2 = exist(dir_path, 'file');
                if exist_result_2 ~= 0
                    error('CoreDiskUtilities:DirectoryDoesNotExist', 'The argument passed to CoreDiskUtilities.GetDirectoryForFile() does not exist or is not a directory.');
                else
                    dir = dir_path;
                end
            end
        end
        
        function filename_set = FilenameSetDiff(filename_set, filenames_to_match, match_path)
            if ~iscell(filenames_to_match)
                filenames_to_match = {filenames_to_match};
            end
            file_set = CoreContainerUtilities.GetFieldValuesFromSet(filename_set, 'Name');
            path_set = CoreContainerUtilities.GetFieldValuesFromSet(filename_set, 'Path');

            matching_files = false(1, numel(file_set));
            
            for match = filenames_to_match
                matching_files = matching_files & strcmp(file_set, match);
                matching_files = matching_files & strcmp(path_set, match_path);
            end
            
            filename_set = filename_set(~matching_files);
        end
        
        function SaveFigure(figure_handle, figure_filename)
            % Exports a figure to high-resolution eps and png
            
            resolution_dpi = 300;
            resolution_str = ['-r' num2str(resolution_dpi)];
            
            print(figure_handle, '-depsc2', resolution_str, figure_filename);   % Export to .eps
            print(figure_handle, '-dpng', resolution_str, figure_filename);     % Export .png
        end
        
        function matlab_name_list = GetAllMatlabFilesInFolders(folders_to_scan)
            % Takes in a list of CorePairs
            
            folders_to_scan = CoreStack(folders_to_scan);
            mfilesFound = CoreStack;
            while ~folders_to_scan.IsEmpty
                next_folder = folders_to_scan.Pop;
                next_plugin_list = CoreDiskUtilities.GetDirectoryFileList(next_folder.First, '*.m');
                for next_plugin = next_plugin_list
                    mfilesFound.Push(CorePair(CoreTextUtilities.StripFileparts(next_plugin{1}), next_folder.Second));
                end
            end
            matlab_name_list = mfilesFound.GetAndClear;
        end        
                    
        function fileNames = GetRecursiveListOfFiles(startDir, filenameFilter)
            % Returns a list of all files in this directory and its
            % subdirectories matching the filename criteria
            
            [absoluteFilePath, ~] = CoreDiskUtilities.GetFullFileParts(startDir);
            filesFound = CoreStack;
            
            directories = CoreDiskUtilities.GetRecursiveListOfDirectories(absoluteFilePath);
            for directory = directories
                fileList = CoreDiskUtilities.GetDirectoryFileList(directory{1}.First, filenameFilter);
                for file = fileList
                    filesFound.Push(fullfile(directory{1}.First, file{1}));
                end
            end
            fileNames = filesFound.GetAndClear;
        end
        
        function list_of_test_classes = GetListOfClassFiles(directory, superclass_name)
            % Returns a list of Matlab classes found in the specified directory which
            % inherit from the given superclass
            
            list_of_test_classes = {};
            list_of_files = CoreDiskUtilities.GetDirectoryFileList(directory, '*.m');
            for file_name = list_of_files
                [~, this_class_name, ~] = fileparts(file_name{1});
                if ~strcmp(this_class_name, superclass_name) && exist(this_class_name, 'class')
                    meta_class = meta.class.fromName(this_class_name);
                    superclasses = meta_class.SuperclassList;
                    if ~isempty(superclasses);
                        superclass_names = superclasses.Name;
                        if ismember(superclass_names, superclass_name, 'rows')
                            list_of_test_classes{end + 1} = this_class_name;
                        end
                    end
                end
            end
        end
    end
end

