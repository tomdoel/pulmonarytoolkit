function CoreAddPaths(varargin)
    % Adds paths required for CoreMat
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    force = nargin > 0 && strcmp(varargin{1}, 'force');
    
    % This version number should be incremented whenever new paths are added to
    % the list
    CoreAddPaths_Version_Number = 3;
    
    persistent Core_PathsHaveBeenSet
    
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    
    if force || (isempty(Core_PathsHaveBeenSet) || Core_PathsHaveBeenSet ~= CoreAddPaths_Version_Number)
        
        path_folders = {};
        
        % List of folders to add to the path
        path_folders{end + 1} = '';
        path_folders{end + 1} = 'File';
        path_folders{end + 1} = 'MexCompile';
        path_folders{end + 1} = 'MTest';
        path_folders{end + 1} = 'Reporting';
        path_folders{end + 1} = 'Types';
        path_folders{end + 1} = 'Utilities';
        path_folders{end + 1} = 'Xml';
        
        AddToPath(path_root, path_folders)
        
        Core_PathsHaveBeenSet = CoreAddPaths_Version_Number;
    end
    
end

function AddToPath(path_root, path_folders)
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
    if ~isempty(full_paths_to_add) 
        addpath(full_paths_to_add{:});
    end
    
end