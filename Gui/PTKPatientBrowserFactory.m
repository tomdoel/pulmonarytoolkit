classdef PTKPatientBrowserFactory < CoreBaseClass
    % PTKPatientBrowserFactory. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Controller
        AppDef
        GuiDatasetState
        ImageDatabase
        InitialPosition
        PatientBrowser
        PatientBrowserSelectedUid
        PatientBrowserSelectedPatientId        
        Reporting
        Title
    end
    
    methods
        function obj = PTKPatientBrowserFactory(controller, image_database, app_def, state, settings, title, reporting)
            obj.Controller = controller;
            obj.ImageDatabase = image_database;
            obj.AppDef = app_def;
            obj.GuiDatasetState = state;
            obj.Reporting = reporting;
            obj.Title = title;
           
            if isempty(settings.PatientBrowserScreenPosition)
                obj.InitialPosition = [100 100 1000 500];
            else
                obj.InitialPosition = settings.PatientBrowserScreenPosition;
            end
            
            obj.AddEventListener(obj.GuiDatasetState, 'SeriesUidChangedEvent', @obj.SeriesChanged);
            obj.AddEventListener(image_database, 'DatabaseHasChanged', @obj.DatabaseHasChanged);
        end
        
        
        function Show(obj)
            % Make Patient Browser visible or bring to the front
            
            if isempty(obj.PatientBrowser)
                obj.PatientBrowser = PTKPatientBrowser(obj.Controller, obj.ImageDatabase, obj.AppDef, obj.InitialPosition, obj.Title, obj.Reporting);
                obj.PatientBrowser.SelectSeries(obj.PatientBrowserSelectedPatientId, obj.PatientBrowserSelectedUid);
                
                obj.PatientBrowser.Show;
            else
                obj.PatientBrowser.SelectSeries(obj.PatientBrowserSelectedPatientId, obj.PatientBrowserSelectedUid);
                
                if obj.PatientBrowser.IsVisible
                    obj.PatientBrowser.BringToFront;
                else
                    obj.PatientBrowser.Show;
                end
            end
        end
        
        function SeriesChanged(obj, ~, ~)
            % Change the currently selected patient and series
            
            patient_id = obj.GuiDatasetState.CurrentPatientId;
            series_uid = obj.GuiDatasetState.CurrentSeriesUid;
            obj.UpdatePatientBrowser(patient_id, series_uid);
        end
        
        function last_position = GetScreenPosition(obj)
            % Gets the current screen coordinates for the Patient Browser
            
            if ~isempty(obj.PatientBrowser)
                last_position = obj.PatientBrowser.GetLastPosition;
            else
                last_position = obj.InitialPosition;
            end
        end
        
        function matches = HandleMatchesPatientBrowser(obj, ui_handle)
            % Check if this handle is the Patient Browser's
            
            matches = (~isempty(obj.PatientBrowser)) && (ui_handle == obj.PatientBrowser.GetContainerHandle(obj.Reporting));
        end

        function Hide(obj)
            % Hide the Patient Browser
            
            if ~isempty(obj.PatientBrowser)
                obj.PatientBrowser.Hide;
                drawnow;
            end
        end
        
        function delete(obj)
            if ~isempty(obj.PatientBrowser)
                delete(obj.PatientBrowser);
            end
        end
        
    end 
    
    methods (Access = private)
        function DatabaseHasChanged(obj, ~, ~)
            % Indicates the underlying image database has changed
            
            if ~isempty(obj.PatientBrowser)
                obj.PatientBrowser.DatabaseHasChanged;
            end
        end
        
        function UpdatePatientBrowser(obj, patient_id, series_uid)
            % Indicates the currently visualised series has changed
            
            obj.PatientBrowserSelectedUid = series_uid;
            obj.PatientBrowserSelectedPatientId = patient_id;
            if ~isempty(obj.PatientBrowser)
                obj.PatientBrowser.SelectSeries(patient_id, series_uid);
            end
        end
    end
end