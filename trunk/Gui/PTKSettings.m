classdef PTKSettings < PTKBaseClass
    % PTKSettings. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     PTKSettings stores gui application settings between sessions. This
    %     class is stored on disk so that settings persist betweek sessions.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        OverlayOpacity = 50
        ImageInfo = []
        SliceNumber = [1 1 1]
        SaveImagePath = ''
        ShowTextLabels = true
        CurrentMarkerColour = 1
        ScreenPosition
        PatientBrowserScreenPosition
        DeveloperMode = false
    end
    
    methods (Static)
        function settings = LoadSettings(reporting)
            try
                settings_filename = PTKDirectories.GetSettingsFilePath;
                if exist(settings_filename, 'file')
                    settings_struct = PTKDiskUtilities.Load(settings_filename);
                    settings = settings_struct.settings;
                else
                    reporting.ShowWarning('PTKSettings:SettingsFileNotFound', 'No settings file found. Will create new one on exit', []);
                    settings = PTKSettings;
                end
                
            catch ex
                reporting.ErrorFromException('PTKSettings:FailedtoLoadSettingsFile', ['Error when loading settings file ' settings_filename '. Try deleting this file.'], ex);
            end
            
            
        end
        
    end
    
    methods
        function obj = PTKSettings
        end
        
        function ApplySettingsToGui(obj, gui, viewer_panel)
            gui.DeveloperMode = obj.DeveloperMode;
            viewer_panel.OverlayOpacity = obj.OverlayOpacity;
            viewer_panel.SliceNumber = obj.SliceNumber;
            viewer_panel.GetMarkerPointManager.ChangeShowTextLabels(obj.ShowTextLabels);
            viewer_panel.GetMarkerPointManager.ChangeCurrentColour(obj.CurrentMarkerColour);
        end
        
        function UpdateSettingsFromGui(obj, gui, viewer_panel)
            obj.DeveloperMode = gui.DeveloperMode;
            obj.OverlayOpacity = viewer_panel.OverlayOpacity;
            obj.SliceNumber = viewer_panel.SliceNumber;
            obj.ShowTextLabels = viewer_panel.GetMarkerPointManager.ShowTextLabels;
            obj.CurrentMarkerColour = viewer_panel.GetMarkerPointManager.CurrentColour;
        end
        
        function SetLastImageInfo(obj, image_info, reporting)
            if ~isequal(image_info, obj.ImageInfo)
                obj.ImageInfo = image_info;
                obj.SaveSettings(reporting);
            end
        end
        
        function SetLastSaveImagePath(obj, image_path, reporting)
            if ~isempty(image_path) && ischar(image_path) && ~strcmp(image_path, obj.SaveImagePath)
                obj.SaveImagePath = image_path;
                obj.SaveSettings(reporting);
            end
        end
        
        function SetPosition(obj, main_screen_position, patient_browser_position)
            obj.ScreenPosition = main_screen_position;
            obj.PatientBrowserScreenPosition = patient_browser_position;
        end
        
        function SaveSettings(obj, reporting)
            
            settings_filename = PTKDirectories.GetSettingsFilePath;
            
            try
                value = [];
                value.settings = obj;
                PTKDiskUtilities.Save(settings_filename, value);
            catch ex
                reporting.ErrorFromException('PTKSettings:FailedtoSaveSettingsFile', ['Unable to save settings file ' settings_filename], ex);
            end
        end        
    end
end

