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
        function application_directory = GetApplicationDirectoryAndCreateIfNecessary
            if ~isempty(PTKConfig.CacheFolder)
                home_directory = PTKConfig.CacheFolder;
            else
                home_directory = CoreDiskUtilities.GetUserDirectory;
            end
            application_directory = PTKSoftwareInfo.ApplicationSettingsFolderName;
            application_directory = fullfile(home_directory, application_directory);  
            if ~exist(application_directory, 'dir')
                mkdir(application_directory);
            end
        end

        function settings_file_path = GetSettingsFilePath
            % Returns the full path to the settings file
            
            settings_dir = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            settings_filename = PTKSoftwareInfo.SettingsFileName;
            settings_file_path = fullfile(settings_dir, settings_filename);
        end
        
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

        function linking_file_path = GetLinkingCacheFilePath
            % Returns the full path to the linking cache file
            
            settings_dir = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            cache_filename = PTKSoftwareInfo.LinkingCacheFileName;
            linking_file_path = fullfile(settings_dir, cache_filename);
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
        
        function log_file_path = GetLogFilePath
            settings_folder = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            log_file_name = PTKSoftwareInfo.LogFileName;
            log_file_path = fullfile(settings_folder, log_file_name);
        end
        
    end
end

