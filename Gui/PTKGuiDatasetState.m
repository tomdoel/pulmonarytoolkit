classdef PTKGuiDatasetState < PTKBaseClass
    % PTKGuiDatasetState. Stores information about the currently loaded series
    %
    %     You do not need to modify this file. To add new functionality, create
    %     new plguins in the Plugins and GuiPlugins folders.
    % 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
   properties (SetAccess = private)
       CurrentSeriesUid
       CurrentPatientId
       CurrentPatientVisibleName
       CurrentSeriesName
       
       CurrentPluginInfo
       CurrentPluginName
       CurrentVisiblePluginName
       CurrentPluginResultIsEdited
   end
   
   events
       SeriesUidChangedEvent
       PluginChangedEvent
   end
   
   methods
       function SetPatientAndSeries(obj, patient_id, series_uid, patient_visible_name, series_name)
           
           if ~strcmp(patient_id, obj.CurrentPatientId) || ~strcmp(series_uid, obj.CurrentSeriesUid)
               obj.CurrentPatientId = patient_id;
               obj.CurrentSeriesUid = series_uid;
               obj.CurrentPatientVisibleName = patient_visible_name;
               obj.CurrentSeriesName = series_name;
               notify(obj, 'SeriesUidChangedEvent');
           end
       end
       
       function ClearPatientAndSeries(obj)
           if ~isempty(obj.CurrentPatientId) || ~isempty(obj.CurrentSeriesUid)
               obj.CurrentPatientId = [];
               obj.CurrentSeriesUid = [];
               obj.CurrentPatientVisibleName = [];
               obj.CurrentSeriesName = [];
               notify(obj, 'SeriesUidChangedEvent');
           end
       end

       function ClearPlugin(obj)
            obj.CurrentPluginInfo = [];
            obj.CurrentPluginName = [];
            obj.CurrentVisiblePluginName = [];
            obj.CurrentPluginResultIsEdited = false;
            notify(obj, 'PluginChangedEvent');
       end
       
       function SetPlugin(obj, plugin_info, plugin_name, plugin_visible_name, is_edited)
            obj.CurrentPluginInfo = plugin_info;
            obj.CurrentPluginName = plugin_name;
            obj.CurrentVisiblePluginName = plugin_visible_name;
            obj.CurrentPluginResultIsEdited = is_edited;
            notify(obj, 'PluginChangedEvent');
       end
       
       function UpdateEditStatus(obj, is_edited)
           if ~isequal(obj.CurrentPluginResultIsEdited, is_edited)
               obj.CurrentPluginResultIsEdited = is_edited;
               notify(obj, 'PluginChangedEvent');
           end
       end
   end
end