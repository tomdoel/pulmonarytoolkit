classdef MimPatientBrowser < GemFigure
    % MimPatientBrowser. Gui for choosing a dataset to view
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        Controller
        BrowserPanel
        LockLoad
        
        LastSeriesSelected
        LastPatientSelected
    end

    methods
        function obj = MimPatientBrowser(controller, image_database, app_def, position, title, reporting)
            obj = obj@GemFigure(title, [], reporting);
            obj.StyleSheet = app_def.GetDefaultStyleSheet;
            obj.Controller = controller;
            obj.ArrowPointer = 'hand';
            obj.LockLoad = false;

            obj.BrowserPanel = MimPatientBrowserPanel(obj, image_database, app_def.GroupPatientsWithSameName, obj);
            obj.AddChild(obj.BrowserPanel);
            
            obj.Resize(position);
        end

        function AddPatient(obj)
            obj.Controller.BringToFront;
            obj.Controller.AddPatient;
            obj.BringToFront;
        end
        
        function DeletePatient(obj, patient_id)
            obj.Controller.DeletePatient(patient_id);
        end
        
        function DeleteSeries(obj, series_uid)
            obj.Controller.DeleteSeries(series_uid);
        end
        
        function SelectSeries(obj, patient_id, series_uid)
            if ~isempty(obj.LastSeriesSelected)
                obj.BrowserPanel.SelectSeries(obj.LastPatientSelected, obj.LastSeriesSelected, false);
            end
            if ~isempty(patient_id)
                obj.BrowserPanel.SelectSeries(patient_id, series_uid, true);
            end
            obj.LastSeriesSelected = series_uid;
            obj.LastPatientSelected = patient_id;
        end
        
        function Resize(obj, position)
            width_pixels = max(200, position(3));
            height_pixels = max(100, position(4));
            new_position = [position(1) position(2) width_pixels height_pixels];
            
            Resize@GemUserInterfaceObject(obj, new_position);
            obj.BrowserPanel.Resize(new_position);
        end

        function DatabaseHasChanged(obj)
            obj.BrowserPanel.DatabaseHasChanged;
            obj.Resize(obj.GetLastPosition);
        end
        
        function SeriesClicked(obj, patient_id, series_uid)
            if obj.LockLoad
                obj.Reporting.ShowMessage('MimPatientBrowser:LoadLock', 'The dataset cannot be loaded because a previous load did not complete. Close and re-open the Patient Browser to allow loading to resume.');
            else
                obj.LockLoad = true;
                obj.SelectSeries(patient_id, series_uid);
                obj.Controller.SeriesClicked(patient_id, series_uid);
                obj.LockLoad = false;
            end
        end

        function Show(obj)
            obj.LockLoad = false;
            Show@GemFigure(obj);
        end
        
        function position = GetLastPosition(obj)
            position = get(obj.GraphicalComponentHandle, 'Position');
        end
        
        function project_id = GetCurrentProject(obj)
            project_id = obj.Controller.GetCurrentProject;
        end        
    end

    methods (Access = protected)
        
        function CustomCloseFunction(obj, src, ~)
            % Override the default behaviour
            obj.Hide();
        end
    end
end
