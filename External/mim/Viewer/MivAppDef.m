classdef MivAppDef < handle
    % MivAppDef. Defines application information
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %        

    properties (Constant, Access = private)
        Name = 'MIV'
        PatientBrowserName = 'Patient Browser: MIV'
        Version = '0.1'
        Colormap = CoreSystemUtilities.BackwardsCompatibilityColormap;        
    end
    
    properties (Access = private)
        DicomMetadata
        FrameworkAppDef
        
        LogFileName = 'log.txt'
        SettingsFileName = 'PTKSettings.mat'
    end
        
    methods
        function [preferred_context, plugin_to_use] = GetPreferredContext(obj, modality)
            % Returns the context that should be automatically used for
            % this dataset, or [] to indicate use the oritinal image
            
            preferred_context = [];
            plugin_to_use = [];
        end

        function context_def = GetContextDef(obj)
            context_def = MivContextDef();
        end
                
        function name = GetName(obj)
            name = MivAppDef.Name;
        end

        function name = GetPatientBrowserName(obj)
            name = MivAppDef.PatientBrowserName;
        end
        
        function name = GetVersion(obj)
            name = MivAppDef.Version;
        end
        
        function direction = GetDefaultOrientation(obj)
            direction = GemImageOrientation.XY;
        end
        
        function style_sheet = GetDefaultStyleSheet(obj)
            style_sheet = MivDefaultStyleSheet();
        end
        
        function logo = GetLogoFilename(~)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            logo = fullfile(path_root, 'MivLogo.jpg');
        end
        
        function logo = GetDefaultPluginIcon(~)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            logo = fullfile(path_root, '..', 'Gui', 'Icons', 'default_plugin.png');
        end
        
        function plugins_folders = GetListOfPluginsFolders(obj)
            shared_plugins_path = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetSharedPluginsDirectory;
            plugins_folders = {shared_plugins_path};
        end
        
        function plugins_folders = GetListOfGuiPluginsFolders(obj)
            shared_plugins_path = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetSharedGuiPluginsDirectory;
            plugins_folders = {shared_plugins_path};
        end
        
        function force_greyscale = ForceGreyscale(~)
            force_greyscale = true;
        end
        
        function enabled = MatNatEnabled(~)
            enabled = false;
        end
        
        function settings_file_path = GetSettingsFilePath(obj)
            % Returns the full path to the settings file
            
            app_dir = obj.FrameworkAppDef.GetFrameworkDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            settings_filename = obj.SettingsFileName;
            settings_file_path = fullfile(app_dir, settings_filename);
        end
        
        function log_file_path = GetLogFilePath(obj)
            % Returns the full path to the log file

            app_folder = obj.GetFrameworkAppDef.GetFrameworkDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            log_file_name = obj.LogFileName;
            log_file_path = fullfile(app_folder, log_file_name);
        end
        
        function cm = GetDefaultColormap(~)
            cm = colormap(MivAppDef.Colormap);
        end

        function framework_app_def = GetFrameworkAppDef(obj)
            if isempty(obj.FrameworkAppDef)
                obj.FrameworkAppDef = MivFrameworkAppDef();
            end
            framework_app_def = obj.FrameworkAppDef;
        end

        function dicom_meta_data = GetDicomMetadata(obj)
            if isempty(obj.DicomMetadata)
                obj.DicomMetadata = MimDicomMetadata();
            end
            dicom_meta_data = obj.DicomMetadata;
        end
        
        function icons_folders = GetIconsFolders(obj)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            shared_icons_path = fullfile(path_root, '..', 'Gui', 'Icons');
            icons_folders = {shared_icons_path};
        end

        function write_verbose = WriteVerboseEntriesToLogFile(obj)
            write_verbose = false;
        end

        function mode = DefaultModeOnNewDataset(~)
            mode = 'Segment';
        end

        function mode = PluginDefaultMode(~)
            mode = 'Plugins';
        end

        function mode = DefaultCategoryName(~)
            mode = 'Uncategorised';
        end

        function group_patients = GroupPatientsWithSameName(~)
            % If this parameter to true, then the patient browser will group together
            % datasets with the same patient name, even if the patient ID is different
            
            group_patients = true;
        end        

        function name = DefaultMarkersName(~)
            % The filename for the initial marker set
            
            name = 'MarkerPoints';
        end

        function confirm = ConfirmBeforeSavingMarkers(~)
            % If true, a dialog will be presented to the user before
            % markers are auto-saved
            
            confirm = false;
        end
    end
end
