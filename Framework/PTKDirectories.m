classdef PTKDirectories < CoreBaseClass
    % PTKDirectories. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Used to find directories used by the Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %


    methods (Static)
        function source_directory = GetSourceDirectory
            % Returns the full path to root of the PTK source code
        
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            source_directory = fullfile(path_root, '..');
        end
        
        function source_directory = GetTestSourceDirectory
            % Returns the full path to root of the PTK test source code
        
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            source_directory = fullfile(path_root, '..', PTKSoftwareInfo.TestSourceDirectory);
        end
        
        function mex_source_directory = GetMexSourceDirectory
            % Returns the full path to the mex file directory
            
            mex_source_directory = fullfile(PTKDirectories.GetSourceDirectory, PTKSoftwareInfo.MexSourceDirectory);
        end

        function plugin_name_list = GetListOfGuiPlugins
            plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(PTKDirectories.GetListOfGuiPluginFolders);
        end
        
        function plugin_folders = GetListOfGuiPluginFolders
            plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(PTKDirectories.GetGuiPluginsPath);
        end
        
        function plugin_name_list = GetListOfUserGuiPlugins
            plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(PTKDirectories.GetListOfUserGuiPluginFolders);
        end
        
        function plugin_folders = GetListOfUserGuiPluginFolders
            plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(PTKDirectories.GetGuiUserPluginsPath);
        end
        
        function plugins_path = GetUserPath
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.UserDirectoryName);
        end
        
        function plugins_path = GetGuiPluginsPath
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.GuiPluginDirectoryName);
        end
        
        function plugins_path = GetGuiUserPluginsPath
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.UserDirectoryName, PTKSoftwareInfo.GuiPluginDirectoryName);
        end        
    end
end

