function TDAddPtkPaths
    global TDPTK_PathsHaveBeenSet
    
    if isempty(TDPTK_PathsHaveBeenSet)
        full_path = mfilename('fullpath');
        [path_root, ~, ~] = fileparts(full_path);
        
        path_folders = {};
        path_folders{end + 1} = 'User';
        path_folders{end + 1} = 'Components';
        path_folders{end + 1} = 'bin';
        path_folders{end + 1} = 'Gui';
        path_folders{end + 1} = 'GuiPlugins';
        path_folders{end + 1} = 'Plugins';
        path_folders{end + 1} = 'Utilities';
        path_folders{end + 1} = 'Library';
        path_folders{end + 1} = 'Interfaces';
        path_folders{end + 1} = 'Types';
        path_folders{end + 1} = 'Framework';
        
        for i = 1 : length(path_folders)
            full_path_name = fullfile(path_root, path_folders{i});
            if exist(full_path_name, 'dir')
                addpath(full_path_name);
            end
        end
        
        % Add additional user-specific paths specified in the file
        % User/TDAddUserPaths.m if it exists
        user_function_name = 'TDAddUserPaths';
        user_add_paths_function = fullfile(path_root, 'User', [user_function_name '.m']);
        if exist(user_add_paths_function, 'file')
            feval(user_function_name);
        end
        
        TDPTK_PathsHaveBeenSet = true;
    end
end
