classdef PTKGuiDatasetState < handle
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
    
   properties
       CurrentSeriesUid
       CurrentPatientId
   end
   
   events
       SeriesUidChangedEvent
   end
   
   methods
       function SetPatientAndSeries(obj, patient_id, series_uid)
           if ~strcmp(patient_id, obj.CurrentPatientId) || ~strcmp(series_uid, obj.CurrentSeriesUid)
               obj.CurrentPatientId = patient_id;
               obj.CurrentSeriesUid = series_uid;
               notify(obj, 'SeriesUidChangedEvent');
           end
       end
       
       function ClearPatientAndSeries(obj)
           if ~isempty(obj.CurrentPatientId) || ~isempty(obj.CurrentSeriesUid)
               obj.CurrentPatientId = [];
               obj.CurrentSeriesUid = [];
               notify(obj, 'SeriesUidChangedEvent');
           end
       end
   end
end