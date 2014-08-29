classdef PTKPatientBrowserFactory < PTKBaseClass
    % PTKPatientBrowserFactory. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Gui
        GuiDataset
        InitialPosition
        PatientBrowser
        PatientBrowserSelectedUid
        PatientBrowserSelectedPatientId        
        Reporting
    end
    
    methods
        function obj = PTKPatientBrowserFactory(gui, gui_dataset, settings, reporting)
            obj.Gui = gui;
            obj.GuiDataset = gui_dataset;
            obj.Reporting = reporting;
           
            if isempty(settings.PatientBrowserScreenPosition)
                obj.InitialPosition = [100 100 1000 500];
            else
                obj.InitialPosition = settings.PatientBrowserScreenPosition;
            end
        end
        
        
        function Show(obj, ~)
            % Make Patient Browser visible or bring to the front
            
            if isempty(obj.PatientBrowser)
                obj.PatientBrowser = PTKPatientBrowser(obj.GuiDataset.GetImageDatabase, obj.Gui, obj.InitialPosition, obj.Reporting);
                obj.PatientBrowser.SelectSeries(obj.PatientBrowserSelectedPatientId, obj.PatientBrowserSelectedUid);
                
                obj.PatientBrowser.Show(obj.Reporting);
            else
                obj.PatientBrowser.SelectSeries(obj.PatientBrowserSelectedPatientId, obj.PatientBrowserSelectedUid);
                
                if obj.PatientBrowser.IsVisible
                    obj.PatientBrowser.BringToFront;
                else
                    obj.PatientBrowser.Show(obj.Reporting);
                end
            end
        end
        
        function DatabaseHasChanged(obj)
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
            
            matches = (~isempty(obj.PatientBrowser)) && (ui_handle == obj.PatientBrowser.GetContainerHandle);
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
end