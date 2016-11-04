classdef PTKAppDef < handle
    % PTKAppDef. Defines application information
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    properties (Access = private)
        FrameworkAppDef
        DicomMetadata
    end
    
    methods
        function [preferred_context, plugin_to_use] = GetPreferredContext(obj, modality)
            % Returns the context that should be automatically used for
            % this dataset, or [] to indicate use the oritinal image
            
            if isempty(modality) || strcmp(modality, 'CT')
                preferred_context = PTKContext.LungROI;
                plugin_to_use = 'PTKLungROI';
            else
                preferred_context = [];
                plugin_to_use = [];
            end
        end

        function context_def = GetContextDef(obj)
            context_def = PTKContextDef;
        end
        
        function name = GetName(obj)
            name = 'Pulmonary Toolkit';
        end
        
        function name = GetVersion(obj)
            name = PTKSoftwareInfo.Version;
        end
        
        function direction = GetDefaultOrientation(obj)
            direction = PTKImageOrientation.Coronal;
        end
        
        function style_sheet = GetDefaultStyleSheet(obj)
            style_sheet = PTKDefaultStyleSheet;
        end

        function logo = GetLogoFilename(obj)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            logo = fullfile(path_root, 'PTKLogo.jpg');
        end

        function logo = GetDefaultPluginIcon(~)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            logo = fullfile(path_root, '..', 'External', 'mim', 'Gui', 'Icons', 'default_plugin.png');
        end
        
        function plugins_folders = GetListOfPluginsFolders(obj)
            app_plugins_path = obj.GetPluginsPath;
            shared_plugins_path = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetSharedPluginsDirectory;
            user_plugins_path = obj.GetUserPluginsPath;
            plugins_folders = {app_plugins_path, shared_plugins_path, user_plugins_path};
        end
        
        function plugins_folders = GetListOfGuiPluginsFolders(obj)
            app_plugins_path = obj.GetGuiPluginsPath;
            shared_plugins_path = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetSharedGuiPluginsDirectory;
            user_plugins_path = obj.GetGuiUserPluginsPath;
            plugins_folders = {app_plugins_path, shared_plugins_path, user_plugins_path};
        end

        function force_greyscale = ForceGreyscale(~)
            force_greyscale = false;
        end
        
        function enabled = MatNatEnabled(~)
            enabled = false;
        end
        
        function settings_file_path = GetSettingsFilePath(obj)
            % Returns the full path to the settings file
            
            app_dir = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            settings_filename = PTKSoftwareInfo.SettingsFileName;
            settings_file_path = fullfile(app_dir, settings_filename);
        end
        
        function log_file_path = GetLogFilePath(obj)
            % Returns the full path to the log file

            app_folder = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            log_file_name = PTKSoftwareInfo.LogFileName;
            log_file_path = fullfile(app_folder, log_file_name);
        end
        
        function cm = GetDefaultColormap(~)
            cm = colormap(PTKSoftwareInfo.Colormap);
        end
        
        function framework_app_def = GetFrameworkAppDef(obj)
            if isempty(obj.FrameworkAppDef)
                obj.FrameworkAppDef = PTKFrameworkAppDef;
            end
            framework_app_def = obj.FrameworkAppDef;
        end

        function dicom_meta_data = GetDicomMetadata(obj)
            if isempty(obj.DicomMetadata)
                obj.DicomMetadata = PTKDicomMetadata;
            end
            dicom_meta_data = obj.DicomMetadata;
        end

        function icons_folders = GetIconsFolders(obj)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            app_icons_path = fullfile(path_root, 'Icons');
            shared_icons_path = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetDefaultIconsDirectory;
            icons_folders = {app_icons_path, shared_icons_path};
        end 
    end
    
    methods (Access = private)
        function plugins_path = GetPluginsPath(~)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', 'Plugins');
        end
        
        function plugins_path = GetUserPluginsPath(obj)
            plugins_path = fullfile(obj.FrameworkAppDef.GetUserPath, 'Plugins');
        end
        
        function plugins_path = GetGuiPluginsPath(~)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', 'Gui', 'GuiPlugins');
        end
        
        function plugins_path = GetGuiUserPluginsPath(obj)
            plugins_path = fullfile(obj.FrameworkAppDef.GetUserPath, 'GuiPlugins');
        end        
    end
end
