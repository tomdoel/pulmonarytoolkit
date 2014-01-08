classdef PTKPatientPanel < PTKPanel
    % PTKPatientPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPatientPanel represents the panel showing patient details in the
    %     Patient Browser.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        CachedMinY
        CachedMaxY
    end
    
    properties (SetAccess = private)
        Name
        Id
    end

    properties (Access = private)
        PatientNameTextControl
        SeriesDescriptions
        
        PatientDetails
        GuiCallback
        
        CachedTableSize
        CachedPanelLocation
        PanelHeight
        PatientNamePosition_Y
        
        LastSelectedSeriesUid
    end
    
    properties (Constant, Access = private)
        PatientNameFontSize = 40
        PatientNameHeight = 40
        PatientNameWidth = 200
        PatientNameLeftPadding = 10        
        BorderSpace = 10;
    end
    
    methods
        function obj = PTKPatientPanel(parent, patient_details, gui_callback, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.Enabled = false;
            obj.PatientDetails = patient_details;
            obj.GuiCallback = gui_callback;
            obj.Name = patient_details.VisibleName;
            obj.Id = patient_details.PatientId;

            obj.PanelHeight = obj.PatientNameHeight + patient_details.GetNumberOfSeries*PTKSeriesDescription.SeriesTextHeight + 2*obj.BorderSpace;
            obj.PatientNamePosition_Y = 1 + obj.GetRequestedHeight - obj.PatientNameHeight - obj.BorderSpace;
        end
        
        function delete(obj)
            obj.DeleteIfHandle(obj.PatientNameTextControl);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
            patient_text_position = [obj.PatientNameLeftPadding position(4)-obj.PatientNameHeight-obj.BorderSpace position(3)-obj.PatientNameLeftPadding obj.PatientNameHeight];
            obj.PatientNameTextControl = uicontrol('Style', 'text', 'Parent', obj.GetContainerHandle(reporting), 'Units', 'pixels', 'FontSize', obj.PatientNameFontSize, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white', 'HorizontalAlignment', 'left', 'String', obj.Name, 'Position', patient_text_position);
            obj.AddStudies(position);
            
            % A series may already have been selected
            if ~isempty(obj.LastSelectedSeriesUid)
                obj.SelectSeries(obj.LastSelectedSeriesUid, true);
            end
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);
            patient_text_position = [obj.PatientNameLeftPadding new_position(4)-obj.PatientNameHeight-obj.BorderSpace new_position(3)-obj.PatientNameLeftPadding obj.PatientNameHeight];
            set(obj.PatientNameTextControl, 'Units', 'Pixels', 'Position', patient_text_position);
            
            for series_index = 1 : numel(obj.SeriesDescriptions)
                y_position = obj.BorderSpace+(series_index-1)*PTKSeriesDescription.SeriesTextHeight;
                series_description_location = [1, y_position, new_position(3), PTKSeriesDescription.SeriesTextHeight];
                obj.SeriesDescriptions(series_index).Resize(series_description_location);
            end
        end
        
        function height = GetRequestedHeight(obj)
            height = obj.PanelHeight;
        end
        
        function SelectSeries(obj, series_uid, selected)
            if selected
                obj.LastSelectedSeriesUid = series_uid;
            else
                obj.LastSelectedSeriesUid = [];
            end
            
            for series_index = 1 : numel(obj.SeriesDescriptions)
                sd = obj.SeriesDescriptions(series_index);
                if strcmp(sd.SeriesUid, series_uid)
                    sd.Select(selected);
                end
            end
        end
        
    end
    
    methods (Access = private)
        
        function AddStudies(obj, new_position)
            datasets = obj.PatientDetails.GetListOfSeries;
            obj.SeriesDescriptions = PTKSeriesDescription.empty;

            for series_index = 1 : length(datasets)
                y_position = obj.BorderSpace+(series_index - 1)*PTKSeriesDescription.SeriesTextHeight;
                series_description_location = [1, y_position, new_position(3), PTKSeriesDescription.SeriesTextHeight];
                
                series = datasets{series_index};
                obj.SeriesDescriptions(series_index) = PTKSeriesDescription(obj, series.Modality, series.StudyName, series.Name, series.Date, series.Time, series.NumberOfImages, obj.Id, series.SeriesUid, obj.GuiCallback);
                obj.SeriesDescriptions(series_index).Resize(series_description_location);
                obj.AddChild(obj.SeriesDescriptions(series_index));
            end
        end

    end    
end