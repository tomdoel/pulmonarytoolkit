classdef MimPatientBrowserPatientsPanel < GemPanel
    % MimPatientBrowserPatientsPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimPatientBrowserPatientsPanel represents the panel showing patient details in the
    %     Patient Browser. 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
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
        
        ImageDatabase
        GuiCallback
        
        GroupPatientsWithSameName
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
        function obj = MimPatientBrowserPatientsPanel(parent, image_database, patient_id, visible_name, total_number_of_series, num_patients, group_patients_with_same_name, gui_callback)
            % Create a new panel showing the series information for one or more patients,
            % each defined by the patient_details vector. This vector may have more than one
            % patient details object if there is more than one patient id corresponding to
            % the same patient, which could occur due to anonymisation
            
            obj = obj@GemPanel(parent);
            obj.GroupPatientsWithSameName = group_patients_with_same_name;
            obj.Enabled = false;
            obj.ImageDatabase = image_database;
            obj.GuiCallback = gui_callback;
            
            obj.Id = patient_id;

            if isempty(visible_name)
                % If there is no patient name, show the patient id
                name = patient_id;
                
            elseif isempty(patient_id)
                % If there is no patient id, show the patient name
                name = visible_name;
                
            else
                if num_patients > 1 || strcmp(visible_name, patient_id)
                    % If there is more than one patient ID, or the ID is the same as the name, we
                    % only show the patient name
                    name = visible_name;
                    
                else
                    % Otherwise show the name and the ID
                    name = [visible_name, ' - ', patient_id];
                end
            end
            obj.Name = name;

            
            obj.PanelHeight = obj.PatientNameHeight + total_number_of_series*MimPatientBrowserSeriesDescription.SeriesTextHeight + ...
                max(0, total_number_of_series-1)*obj.SpacingBetweenSeries + obj.ListTopMargin + obj.ListBottomMargin + obj.TopMargin + obj.BottomMargin;
            obj.PatientNamePosition_Y = 1 + obj.PanelHeight - obj.PatientNameHeight - obj.TopMargin;
                        
            obj.PatientNameTextControl = GemText(obj, obj.Name, ['Patient name: ', obj.Name], 'PatientName');
            obj.PatientNameTextControl.FontSize = obj.PatientNameFontSize;
            obj.AddChild(obj.PatientNameTextControl);
            obj.AddEventListener(obj.PatientNameTextControl, 'TextRightClicked', @obj.PatientRightClicked);
            
            obj.SeriesDescriptionsList = GemListBox(obj);
            obj.SeriesDescriptionsList.TopMargin = obj.ListTopMargin;
            obj.SeriesDescriptionsList.BottomMargin = obj.ListBottomMargin;
            obj.SeriesDescriptionsList.SpacingBetweenItems = obj.SpacingBetweenSeries;
            obj.AddChild(obj.SeriesDescriptionsList);
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemPanel(obj, position);
            obj.AddStudies;
        end
        
        function Resize(obj, new_position)
            Resize@GemPanel(obj, new_position);
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
        
        function AddStudies(obj)
            datasets = obj.ImageDatabase.GetAllSeriesForThisPatient(obj.GuiCallback.GetCurrentProject, obj.Id, obj.GroupPatientsWithSameName);
            
            obj.SeriesDescriptionsList.ClearItems;
            
            for series_index = 1 : length(datasets)
                series = datasets{series_index};
                obj.SeriesDescriptionsList.AddItem(MimPatientBrowserSeriesDescription(obj.SeriesDescriptionsList, series.Modality, series.StudyName, series.Name, series.Date, series.Time, series.NumberOfImages, obj.Id, series.SeriesUid, obj.GuiCallback));
            end
        end

    end    
end