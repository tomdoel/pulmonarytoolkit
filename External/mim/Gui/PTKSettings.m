classdef PTKSettings < CoreBaseClass
    % PTKSettings. Part of the internal gui for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the TD MIM Toolkit.
    %
    %     PTKSettings stores gui application settings between sessions. This
    %     class is stored on disk so that settings persist betweek sessions.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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
        LastUidForPatientMap
        LastMarkerSetForPatientMap
    end
    
    properties (Transient, Access = private)
        SettingsFilename
    end
    
    methods (Static)
        function settings = LoadSettings(app_def, reporting)
            try
                settings_filename = app_def.GetSettingsFilePath;
                if exist(settings_filename, 'file')
                    settings_struct = MimDiskUtilities.Load(settings_filename);
                    settings = settings_struct.settings;
                else
                    reporting.Log('No settings file found. Will create new one on exit');
                    settings = PTKSettings;
                end
                settings.SettingsFilename = settings_filename;
                if isempty(settings.LastMarkerSetForPatientMap)
                    settings.LastMarkerSetForPatientMap = containers.Map;
                end
                if isempty(settings.LastUidForPatientMap)
                    settings.LastUidForPatientMap = containers.Map;
                end
                
                
            catch ex
                reporting.ErrorFromException('PTKSettings:FailedtoLoadSettingsFile', ['Error when loading settings file ' settings_filename '. Try deleting this file.'], ex);
            end
            
            
        end
        
    end
    
    methods
        function obj = PTKSettings
            obj.LastUidForPatientMap = containers.Map;
            obj.LastMarkerSetForPatientMap = containers.Map;
        end
        
        function ApplySettingsToGui(obj, gui, viewer_panel)
            gui.DeveloperMode = obj.DeveloperMode;
            viewer_panel.OverlayOpacity = obj.OverlayOpacity;
            viewer_panel.SliceNumber = obj.SliceNumber;
            viewer_panel.MarkerImageDisplayParameters.ShowLabels = obj.ShowTextLabels;
            viewer_panel.NewMarkerColour = obj.CurrentMarkerColour;
        end
        
        function UpdateSettingsFromGui(obj, gui, viewer_panel)
            obj.DeveloperMode = gui.DeveloperMode;
            obj.OverlayOpacity = viewer_panel.OverlayOpacity;
            obj.SliceNumber = viewer_panel.SliceNumber;
            obj.ShowTextLabels = viewer_panel.MarkerImageDisplayParameters.ShowLabels;
            obj.CurrentMarkerColour = viewer_panel.NewMarkerColour;
        end
        
        function SetLastImageInfo(obj, image_info, reporting)
            if ~isequal(image_info, obj.ImageInfo)
                obj.ImageInfo = image_info;
                obj.SaveSettings(reporting);
            end
        end
        
        function AddLastPatientUid(obj, patient_id, series_uid)
            if isempty(obj.LastUidForPatientMap)
                obj.LastUidForPatientMap = containers.Map;
            end
            obj.LastUidForPatientMap(patient_id) = series_uid;
        end
        
        function AddLastMarkerSet(obj, series_uid, marker_set_name)
            if isempty(obj.LastMarkerSetForPatientMap)
                obj.LastMarkerSetForPatientMap = containers.Map;
            end
            obj.LastMarkerSetForPatientMap(series_uid) = marker_set_name;
        end
        
        function RemoveLastMarkerSet(obj, series_uid, marker_set_name)
            if ~isempty(obj.LastMarkerSetForPatientMap) && obj.LastMarkerSetForPatientMap.isKey(series_uid) && strcmp(obj.LastMarkerSetForPatientMap(series_uid), marker_set_name)
                obj.LastMarkerSetForPatientMap.remove(series_uid);
            end
        end

        function series_uid = GetLastPatientUid(obj, patient_id)
            if obj.LastUidForPatientMap.isKey(patient_id)
                series_uid = obj.LastUidForPatientMap(patient_id);
            else 
                series_uid = [];
            end
        end

        function marker_set_name = GetLastMarkerSetName(obj, series_uid)
            if isempty(obj.LastMarkerSetForPatientMap)
                obj.LastMarkerSetForPatientMap = containers.Map;
            end
            if obj.LastMarkerSetForPatientMap.isKey(series_uid)
                marker_set_name = obj.LastMarkerSetForPatientMap(series_uid);
            else 
                marker_set_name = [];
            end
        end
        
        function RemoveLastPatientUid(obj, series_uids)
            for key = obj.LastUidForPatientMap.keys
                if any(strcmp(obj.LastUidForPatientMap(key{1}), series_uids))
                    obj.LastUidForPatientMap.remove(key{1});
                end
            end
            for key = obj.LastMarkerSetForPatientMap.keys
                if any(strcmp(obj.LastMarkerSetForPatientMap(key{1}), series_uids))
                    obj.LastMarkerSetForPatientMap.remove(key{1});
                end
            end
            
            if ~isempty(obj.ImageInfo) && any(strcmp(obj.ImageInfo.ImageUid, series_uids))
                obj.ImageInfo = [];
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
            
            settings_filename = obj.SettingsFilename;
            
            try
                value = [];
                value.settings = obj;
                if isempty(settings_filename)
                    reporting.ShowWarning('PTKSettings:NoSettingsFilename', 'The settings file could not be saved as the settings filename was not known.', []);
                else
                    MimDiskUtilities.Save(settings_filename, value);
                end
            catch ex
                reporting.ErrorFromException('PTKSettings:FailedtoSaveSettingsFile', ['Unable to save settings file ' settings_filename], ex);
            end
        end        
    end
end

