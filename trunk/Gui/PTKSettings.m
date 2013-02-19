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
        PreviousImageInfos
        Window = 1000
        Level = 1000
        SliceNumber = [1 1 1]
        Orientation = PTKImageOrientation.Coronal
        ShowImage = true
        ShowOverlay = true
        SaveImagePath = ''
        ClosestDistanceForReplaceMarker = 5
        ShowTextLabels = true
        SliceSkip = 10
        CurrentMarkerColour = 1
        ScreenPosition
    end
    
    methods (Static)
        function settings = LoadSettings(viewer_panel, reporting)
            try
                settings_filename = PTKDirectories.GetSettingsFilePath;
                if exist(settings_filename, 'file')
                    settings_struct = load(settings_filename);
                    settings = settings_struct.settings;
                else
                    reporting.ShowWarning('PTKSettings:SettingsFileNotFound', 'No settings file found. Will create new one on exit', []);
                    settings = PTKSettings;
                end
                
            catch ex
                reporting.ErrorFromException('PTKSettings:FailedtoLoadSettingsFile', ['Error when loading settings file ' settings_filename '. Try deleting this file.'], ex);
            end
            
            viewer_panel.Window = settings.Window;
            viewer_panel.Level = settings.Level;
            viewer_panel.OverlayOpacity = settings.OverlayOpacity;
            viewer_panel.Level = settings.Level;
            viewer_panel.SliceNumber = settings.SliceNumber;
            viewer_panel.Orientation = settings.Orientation;
            viewer_panel.ShowImage = settings.ShowImage;
            viewer_panel.ShowOverlay = settings.ShowOverlay;
            viewer_panel.MarkerPointManager.ClosestDistanceForReplaceMarker = settings.ClosestDistanceForReplaceMarker;
            viewer_panel.MarkerPointManager.ChangeShowTextLabels(settings.ShowTextLabels);
            viewer_panel.SliceSkip = settings.SliceSkip;
            viewer_panel.MarkerPointManager.ChangeCurrentColour(settings.CurrentMarkerColour);
            
        end
        
    end
    
    methods
        function obj = PTKSettings
            % Objects should be instantiated in the constructor, not in the
            % property list. Otherwise all objects of this class will have the
            % same instance of the property
            obj.PreviousImageInfos = containers.Map;
        end
        
        function SaveSettings(obj, viewer_panel, reporting)
            % Also save settings from the image panel
            obj.OverlayOpacity = viewer_panel.OverlayOpacity;
            obj.Window = viewer_panel.Window;
            obj.Level = viewer_panel.Level;
            obj.SliceNumber = viewer_panel.SliceNumber;
            obj.Orientation = viewer_panel.Orientation;
            obj.ShowImage = viewer_panel.ShowImage;
            obj.ShowOverlay = viewer_panel.ShowOverlay;
            obj.ClosestDistanceForReplaceMarker = viewer_panel.MarkerPointManager.ClosestDistanceForReplaceMarker;
            obj.ShowTextLabels = viewer_panel.MarkerPointManager.ShowTextLabels;
            obj.SliceSkip = viewer_panel.SliceSkip;
            obj.CurrentMarkerColour = viewer_panel.MarkerPointManager.CurrentColour;
            
            settings_filename = PTKDirectories.GetSettingsFilePath;
            
            try
                settings = obj; %#ok<NASGU>
                save(settings_filename, 'settings');
            catch ex
                reporting.ErrorFromException('PTKSettings:FailedtoSaveSettingsFile', ['Unable to save settings file ' settings_filename], ex);
            end
        end        
    end
end

