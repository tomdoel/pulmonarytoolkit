classdef PTKCombinedImageDatabaseController < handle
    % PTKCombinedImageDatabaseController. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        GuiCallback
    end
    
    methods
        function obj = PTKCombinedImageDatabaseController(gui_callback)
            obj.GuiCallback = gui_callback;
        end
        
        function PatientClicked(obj, patient_id)
            obj.GuiCallback.LoadPatient(patient_id);
        end
        
        function SeriesClicked(obj, series_uid)
            obj.GuiCallback.LoadFromPatientBrowser(series_uid);
        end
        
        function AddPatient(obj)
            obj.GuiCallback.ImportMultipleFiles;
        end
        
        function AddSeries(obj)
            obj.GuiCallback.ImportMultipleFiles;
        end
        
        function DeletePatient(obj, patient_id)
            obj.GuiCallback.DeletePatient(patient_id);
        end
        
        function DeleteSeries(obj, series_uid)
            obj.GuiCallback.DeleteDataset(series_uid);
        end

        function BringToFront(obj)
            obj.GuiCallback.BringToFront;
        end
        
        function UnlinkDataset(obj, series_uid)
            obj.GuiCallback.UnlinkDataset(series_uid);
        end
    end    
end