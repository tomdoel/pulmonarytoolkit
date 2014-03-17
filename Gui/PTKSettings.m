classdef PTKSettings < handle
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
        
        function ApplySettingsToViewerPanel(obj, viewer_panel)
            viewer_panel.OverlayOpacity = obj.OverlayOpacity;
            viewer_panel.SliceNumber = obj.SliceNumber;
            viewer_panel.MarkerPointManager.ChangeShowTextLabels(obj.ShowTextLabels);
            viewer_panel.MarkerPointManager.ChangeCurrentColour(obj.CurrentMarkerColour);
        end
        
        function SaveSettings(obj, viewer_panel, reporting)
            
            % Also save settings from the image panel
            obj.OverlayOpacity = viewer_panel.OverlayOpacity;
            obj.SliceNumber = viewer_panel.SliceNumber;
            obj.ShowTextLabels = viewer_panel.MarkerPointManager.ShowTextLabels;
            obj.CurrentMarkerColour = viewer_panel.MarkerPointManager.CurrentColour;
            
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

