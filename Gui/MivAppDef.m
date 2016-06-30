classdef MivAppDef < handle
    % MivAppDef. Defines application information
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    properties (Constant, Access = private)
        Name = 'MIV'
        Version = '0.1'
    end
    
    properties (Access = private)
        FrameworkAppDef
    end
        
    methods
        function [preferred_context, plugin_to_use] = GetPreferredContext(obj, modality)
            % Returns the context that should be automatically used for
            % this dataset, or [] to indicate use the oritinal image
            
            preferred_context = [];
            plugin_to_use = [];
        end

        function context_def = GetContextDef(obj)
            context_def = MivContextDef;
        end
                
        function name = GetName(obj)
            name = MivAppDef.Name;
        end
        
        function name = GetVersion(obj)
            name = MivAppDef.Version;
        end
        
        function direction = GetDefaultOrientation(obj)
            direction = PTKImageOrientation.Axial;
        end
        
        function style_sheet = GetDefaultStyleSheet(obj)
            style_sheet = MivDefaultStyleSheet;
        end
        
        function logo = GetLogoFilename(obj)
            logo = 'MivLogo.jpg';
        end
        
        function plugins_path = GetPluginsPath(~)
            plugins_path = [];
        end
        
        function plugins_path = GetUserPluginsPath(~)
            plugins_path = [];
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
    end
end
