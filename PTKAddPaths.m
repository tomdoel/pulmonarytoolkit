function PTKAddPaths(varargin)
    
    reset = nargin > 0 && strcmp(varargin{1}, 'reset');
    force = nargin > 0 && strcmp(varargin{1}, 'force');
    
    if reset
        path(pathdef);
        force = true;
    end
    
    % This version number should be incremented whenever new paths are added to
    % the list
    PTKAddPaths_Version_Number = 6;
    
    persistent PTK_PathsHaveBeenSet
    
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    cached_pathname = [path_root '.' PTKAddPaths_Version_Number];
    
    if force || (isempty(PTK_PathsHaveBeenSet) || ~strcmp(PTK_PathsHaveBeenSet, cached_pathname))
        
        path_folders = {};
        
        % List of folders to add to the path
        path_folders{end + 1} = '';
        path_folders{end + 1} = 'User';
        path_folders{end + 1} = 'bin';
        path_folders{end + 1} = 'Gui';
        path_folders{end + 1} = 'Library';
        path_folders{end + 1} = 'Test';
        path_folders{end + 1} = fullfile('Library', 'Airways');
        path_folders{end + 1} = fullfile('Library', 'Analysis');
        path_folders{end + 1} = fullfile('Library', 'Conversion');
        path_folders{end + 1} = fullfile('Library', 'Dicom');
        path_folders{end + 1} = fullfile('Library', 'GuiComponents');
        path_folders{end + 1} = fullfile('Library', 'Lobes');
        path_folders{end + 1} = fullfile('Library', 'Lungs');
        path_folders{end + 1} = fullfile('Library', 'Registration');
        path_folders{end + 1} = fullfile('Library', 'Segmentation');
        path_folders{end + 1} = fullfile('Library', 'Test');
        path_folders{end + 1} = fullfile('Library', 'Types');
        path_folders{end + 1} = fullfile('Library', 'Vessels');
        path_folders{end + 1} = fullfile('Library', 'Visualisation');
        path_folders{end + 1} = 'Framework';
        path_folders{end + 1} = 'Scripts';
        
        path_folders{end + 1} = fullfile('External', 'coremat');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui', 'Controllers');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui', 'DatabaseSidePanel');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui', 'Panels');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui', 'PatientBrowser');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui', 'Modes');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui', 'Tools');
        path_folders{end + 1} = fullfile('External', 'mim', 'Gui', 'ViewerPanel');
        path_folders{end + 1} = fullfile('External', 'mim', 'Framework');
        path_folders{end + 1} = fullfile('External', 'mim', 'Legacy');
        path_folders{end + 1} = fullfile('External', 'mim', 'Library', 'Filters');
        path_folders{end + 1} = fullfile('External', 'mim', 'Library', 'Visualisation');
        path_folders{end + 1} = fullfile('External', 'mim', 'Library', 'Conversion');
        path_folders{end + 1} = fullfile('External', 'mim', 'Library', 'File');
        path_folders{end + 1} = fullfile('External', 'mim', 'Library', 'Segmentation');
        path_folders{end + 1} = fullfile('External', 'mim', 'Library', 'Types');
        path_folders{end + 1} = fullfile('External', 'mim', 'Library', 'Utilities');
        path_folders{end + 1} = fullfile('External', 'mim', 'Viewer');
        path_folders{end + 1} = fullfile('External', 'mim', 'WebSocket');
        path_folders{end + 1} = fullfile('External', 'mim', 'WebSocket', 'Models');
        path_folders{end + 1} = fullfile('External', 'gem');
        path_folders{end + 1} = fullfile('External', 'matnat');
        path_folders{end + 1} = fullfile('External', 'dicomat');
        path_folders{end + 1} = fullfile('External', 'gerardus', 'matlab', 'PointsToolbox');
        path_folders{end + 1} = fullfile('External', 'stlwrite');
        path_folders{end + 1} = fullfile('External', 'npReg');
        path_folders{end + 1} = fullfile('External', 'depmat');
        path_folders{end + 1} = fullfile('External', 'MatlabWebSocket', 'src');
        path_folders{end + 1} = fullfile('External', 'jsonlab-1.5', 'jsonlab-1.5');
        path_folders{end + 1} = fullfile('External', 'npReg', 'npRegLib');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'subfunctions');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'gipl');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'hdr');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'isi');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'mha');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'nii');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'par');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'v3d');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'vff');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'vmp');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'vtk');
        path_folders{end + 1} = fullfile('External', 'ReadData3D', 'xif');
        
        AddToPath(path_root, path_folders);
        
        CoreAddPaths(varargin{:});
        MatNatAddPaths(varargin{:});
        
        % Now add the plugins (have to do this afterwards, because we rely on
        % library functions, so the library paths have to be set first)
        path_folders = {};
        
        plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(fullfile(path_root, 'Gui', 'GuiPlugins'));
        for folder = plugin_folders
            path_folders{end + 1} = folder{1}.First;
        end
        
        plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(fullfile(path_root, 'Plugins'));
        for folder = plugin_folders
            path_folders{end + 1} = folder{1}.First;
        end
        
        plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(fullfile(path_root, 'External', 'mim', 'Plugins'));
        for folder = plugin_folders
            path_folders{end + 1} = folder{1}.First;
        end

        plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(fullfile(path_root, 'External', 'mim', 'Gui', 'GuiPlugins'));
        for folder = plugin_folders
            path_folders{end + 1} = folder{1}.First;
        end
        
        AddToPath('', path_folders);
        
        PTK_PathsHaveBeenSet = cached_pathname;
    end
    
    % Add additional user-specific paths specified in the file
    % User/PTKAddUserPaths.m if it exists
    if ~PTKSoftwareInfo.DemoMode
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