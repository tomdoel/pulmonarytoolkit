function MatNatAddPaths(varargin)
    %     Adds paths for MatNat
    %
    %     Licence
    %     -------
    %     Part of MatNat. https://github.com/tomdoel/matnat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    force = nargin > 0 && strcmp(varargin{1}, 'force');
    
    % This version number should be incremented whenever new paths are added to
    % the list
    MatNatAddPaths_Version_Number = 1;
    
    persistent MatNat_PathsHaveBeenSet
    
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    
    if force || (isempty(MatNat_PathsHaveBeenSet) || MatNat_PathsHaveBeenSet ~= MatNatAddPaths_Version_Number)
        
        path_folders = {};
        
        % List of folders to add to the path
        path_folders{end + 1} = '';
        path_folders{end + 1} = fullfile('External', 'encoder', 'encoder');
        
        AddToPath(path_root, path_folders)
        
        MatNat_PathsHaveBeenSet = MatNatAddPaths_Version_Number;
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