function PTKAddPtkPaths(varargin)
    
    force = nargin > 0 && strcmp(varargin{1}, 'force');
    
    % This version number should be incremented whenever new paths are added to
    % the list
    PTKAddPtkPaths_Version_Number = 1;
    
    persistent PTK_PathsHaveBeenSet
    
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    
    if force || (isempty(PTK_PathsHaveBeenSet) || PTK_PathsHaveBeenSet ~= PTKAddPtkPaths_Version_Number)
        
        path_folders = {};
        
        % List of folders to add to the path
        path_folders{end + 1} = '';
        path_folders{end + 1} = 'User';
        path_folders{end + 1} = 'bin';
        path_folders{end + 1} = 'Gui';
        path_folders{end + 1} = fullfile('Gui', 'GuiPlugins');
        path_folders{end + 1} = 'Plugins';
        path_folders{end + 1} = 'Library';
        path_folders{end + 1} = fullfile('Library', 'Airways');
        path_folders{end + 1} = fullfile('Library', 'Analysis');
        path_folders{end + 1} = fullfile('Library', 'File');
        path_folders{end + 1} = fullfile('Library', 'GuiComponents');
        path_folders{end + 1} = fullfile('Library', 'Interfaces');
        path_folders{end + 1} = fullfile('Library', 'Lobes');
        path_folders{end + 1} = fullfile('Library', 'Lungs');
        path_folders{end + 1} = fullfile('Library', 'Registration');
        path_folders{end + 1} = fullfile('Library', 'Types');
        path_folders{end + 1} = fullfile('Library', 'Utilities');
        path_folders{end + 1} = fullfile('Library', 'Visualisation');
        path_folders{end + 1} = 'Framework';
        path_folders{end + 1} = fullfile('External', 'gerardus', 'matlab', 'PointsToolbox');
        
        full_paths_to_add = {};
        
        % Get the full path for each folder but check it exists before adding to
        % the list of paths to add
        for i = 1 : length(path_folders)
            full_path_name = fullfile(path_root, path_folders{i});
            if exist(full_path_name, 'dir')
                full_paths_to_add{end + 1} = full_path_name;
            end
        end
        
        % Add all the paths together (much faster than adding them individually)
        addpath(full_paths_to_add{:});
        
        PTK_PathsHaveBeenSet = PTKAddPtkPaths_Version_Number;
    end
    
    % Add additional user-specific paths specified in the file
    % User/PTKAddUserPaths.m if it exists
    user_function_name = 'PTKAddUserPaths';
    user_add_paths_function = fullfile(path_root, 'User', [user_function_name '.m']);
    if exist(user_add_paths_function, 'file')
        if force
            feval(user_function_name, 'force');
        else
            feval(user_function_name);
        end
    end
end