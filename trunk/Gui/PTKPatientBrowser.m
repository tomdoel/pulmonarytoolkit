classdef PTKPatientBrowser < PTKFigure
    % PTKPatientBrowser. Gui for choosing a dataset to view
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        BrowserPanel
        GuiCallback
        LockLoad
        
        LastSeriesSelected
        LastPatientSelected
        Reporting
    end

    methods
        function obj = PTKPatientBrowser(image_database, gui_callback, position, reporting)
            obj = obj@PTKFigure('Patient Browser : Pulmonary Toolkit', []);
            obj.Reporting = reporting;
            obj.ArrowPointer = 'hand';
            obj.GuiCallback = gui_callback;
            obj.LockLoad = false;

            obj.BrowserPanel = PTKPatientBrowserPanel(obj, image_database, obj, reporting);
            obj.AddChild(obj.BrowserPanel);
            
            obj.Resize(position);
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
            
            Resize@PTKUserInterfaceObject(obj, new_position);
            obj.BrowserPanel.Resize(new_position);
        end

        function DatabaseHasChanged(obj)
            obj.BrowserPanel.DatabaseHasChanged;
            obj.Resize(obj.Position);
        end
        
        function LoadFromPatientBrowser(obj, patient_id, series_uid)
            if obj.LockLoad
                obj.Reporting.ShowMessage('PTKPatientBrowser:LoadLock', 'The dataset cannot be loaded because a previous load did not complete. Close and re-open the Patient Browser to allow loading to resume.');
            else
                obj.LockLoad = true;
                obj.SelectSeries(patient_id, series_uid);
                obj.GuiCallback.LoadFromPatientBrowser(series_uid);
                obj.LockLoad = false;
            end
        end

        function Show(obj, reporting)
            obj.LockLoad = false;
            Show@PTKFigure(obj, reporting);
        end
        
        function position = GetLastPosition(obj)
            position = get(obj.GraphicalComponentHandle, 'Position');
        end
    end

    methods (Access = protected)
        
        function CustomCloseFunction(obj, src, ~)
            % Override the default behaviour
            obj.Hide;
        end
    end
end
