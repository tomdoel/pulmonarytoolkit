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
        
        SeriesDescriptionsList
        
        PatientDetails
        GuiCallback
        
        PanelHeight
        PatientNamePosition_Y
        
        LastSelectedSeriesUid
        
        TextClickedListeners
    end
    
    properties (Constant, Access = private)
        PatientNameFontSize = 40
        PatientNameHeight = 40
        PatientNameWidth = 200
        PatientNameLeftPadding = 10        
        TopMargin = 10
        BottomMargin = 10
        ListTopMargin = 5
        ListBottomMargin = 5
        SpacingBetweenSeries = 0
    end
    
    methods
        function obj = PTKPatientPanel(parent, patient_details, gui_callback, reporting)
            % Create a new panel showing the series information for one or more patients,
            % each defined by the patient_details vector. This vector may have more than one
            % patient details object if there is more than one patient id corresponding to
            % the same patient, which could occur due to anonymisation
            
            obj = obj@PTKPanel(parent, reporting);
            obj.Enabled = false;
            obj.PatientDetails = patient_details;
            obj.GuiCallback = gui_callback;
            
            obj.Id = patient_details(1).PatientId;

            if isempty(patient_details(1).VisibleName)
                % If there is no patient name, show the patient id
                name = patient_details(1).PatientId;
                
            elseif isempty(patient_details(1).PatientId)
                % If there is no patient id, show the patient name
                name = patient_details(1).VisibleName;
                
            else
                if numel(patient_details) > 1 || strcmp(patient_details(1).VisibleName, patient_details(1).PatientId)
                    % If there is more than one patient ID, or the ID is the same as the name, we
                    % only show the patient name
                    name = patient_details(1).VisibleName;
                    
                else
                    % Otherwise show the name and the ID
                    name = [patient_details(1).VisibleName, ' - ', patient_details(1).PatientId];
                end
            end
            obj.Name = name;

            total_number_of_series = sum(arrayfun(@(x) x.GetNumberOfSeries, patient_details));
            obj.PanelHeight = obj.PatientNameHeight + total_number_of_series*PTKSeriesDescription.SeriesTextHeight + ...
                max(0, total_number_of_series-1)*obj.SpacingBetweenSeries + obj.ListTopMargin + obj.ListBottomMargin + obj.TopMargin + obj.BottomMargin;
            obj.PatientNamePosition_Y = 1 + obj.PanelHeight - obj.PatientNameHeight - obj.TopMargin;
                        
            obj.PatientNameTextControl = PTKText(obj, obj.Name, ['Patient name: ', obj.Name], 'PatientName');
            obj.PatientNameTextControl.FontSize = obj.PatientNameFontSize;
            obj.AddChild(obj.PatientNameTextControl, obj.Reporting);
            obj.AddEventListener(obj.PatientNameTextControl, 'TextRightClicked', @obj.PatientRightClicked);
            
            obj.SeriesDescriptionsList = PTKListBox(obj, reporting);
            obj.SeriesDescriptionsList.TopMargin = obj.ListTopMargin;
            obj.SeriesDescriptionsList.BottomMargin = obj.ListBottomMargin;
            obj.SeriesDescriptionsList.SpacingBetweenItems = obj.SpacingBetweenSeries;
            obj.AddChild(obj.SeriesDescriptionsList, obj.Reporting);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
            obj.AddStudies(position);
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);
            patient_text_position = [obj.PatientNameLeftPadding 1+new_position(4)-obj.PatientNameHeight-obj.TopMargin new_position(3)-obj.PatientNameLeftPadding obj.PatientNameHeight];
            obj.PatientNameTextControl.Resize(patient_text_position);
            
            list_height = max(1, new_position(4) - obj.PatientNameHeight - obj.TopMargin - obj.BottomMargin);
            obj.SeriesDescriptionsList.Resize([1, obj.BottomMargin, new_position(3), list_height]);
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.PanelHeight;
        end
        
        function SelectSeries(obj, series_uid, selected)
            obj.SeriesDescriptionsList.SelectItem(series_uid, selected);
        end

        function DeletePatientSelected(obj, ~, ~)
            obj.DeletePatient;
        end

        function DeletePatient(obj)
            parent_figure = obj.GetParentFigure;
            parent_figure.ShowWaitCursor;
            obj.GuiCallback.BringToFront;
            
            gui_callback = obj.GuiCallback;
            patient_id = obj.Id;
            gui_callback.DeletePatient(patient_id);
            
            parent_figure.BringToFront;
            parent_figure.HideWaitCursor;
        end
        
    end
    
    methods (Access = private)
        
        function PatientRightClicked(obj, ~, ~)
            if isempty(get(obj.PatientNameTextControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_patient = uimenu(context_menu, 'Label', 'Delete this patient', 'Callback', @obj.DeletePatientSelected); %#ok<NASGU>
                set(obj.PatientNameTextControl.GraphicalComponentHandle, 'uicontextmenu', context_menu);
            end
        end
        
        function AddStudies(obj, new_position)
            datasets = [];
            for patient_details = obj.PatientDetails
                datasets = [datasets, patient_details.GetListOfSeries];
            end
            
            obj.SeriesDescriptionsList.ClearItems;
            
            for series_index = 1 : length(datasets)
                series = datasets{series_index};
                obj.SeriesDescriptionsList.AddItem(PTKSeriesDescription(obj.SeriesDescriptionsList, series.Modality, series.StudyName, series.Name, series.Date, series.Time, series.NumberOfImages, obj.Id, series.SeriesUid, obj.GuiCallback, obj.Reporting));
            end
        end

    end    
end