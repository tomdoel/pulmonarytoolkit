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
        
        TextClickedListeners
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
            
            obj.Id = patient_details.PatientId;

            if isempty(patient_details.VisibleName)
                name = patient_details.PatientId;
            elseif isempty(patient_details.PatientId)
                name = patient_details.VisibleName;
            else
                name = [patient_details.VisibleName, ' - ', patient_details.PatientId];
            end
            obj.Name = name;

            obj.PanelHeight = obj.PatientNameHeight + patient_details.GetNumberOfSeries*PTKSeriesDescription.SeriesTextHeight + 2*obj.BorderSpace;
            obj.PatientNamePosition_Y = 1 + obj.PanelHeight - obj.PatientNameHeight - obj.BorderSpace;
                        
            obj.PatientNameTextControl = PTKText(obj, obj.Name, ['Patient name: ', obj.Name], 'PatientName');
            obj.PatientNameTextControl.FontSize = obj.PatientNameFontSize;
            obj.AddChild(obj.PatientNameTextControl);
            obj.TextClickedListeners = addlistener(obj.PatientNameTextControl, 'TextRightClicked', @obj.PatientRightClicked);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
            patient_text_position = [obj.PatientNameLeftPadding position(4)-obj.PatientNameHeight-obj.BorderSpace position(3)-obj.PatientNameLeftPadding obj.PatientNameHeight];
            
            obj.AddStudies(position);
            
            % A series may already have been selected
            if ~isempty(obj.LastSelectedSeriesUid)
                obj.SelectSeries(obj.LastSelectedSeriesUid, true);
            end
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);
            patient_text_position = [obj.PatientNameLeftPadding new_position(4)-obj.PatientNameHeight-obj.BorderSpace new_position(3)-obj.PatientNameLeftPadding obj.PatientNameHeight];
            obj.PatientNameTextControl.Resize(patient_text_position);
            
            for series_index = 1 : numel(obj.SeriesDescriptions)
                y_position = obj.BorderSpace+(series_index-1)*PTKSeriesDescription.SeriesTextHeight;
                series_description_location = [1, y_position, new_position(3), PTKSeriesDescription.SeriesTextHeight];
                obj.SeriesDescriptions(series_index).Resize(series_description_location);
            end
        end
        
        function height = GetRequestedHeight(obj, width)
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

        function DeletePatientSelected(obj, ~, ~)
            obj.DeletePatient;
        end

        function DeletePatient(obj)
            choice = questdlg('Do you want to delete this patient?', ...
                'Delete patient', 'Delete', 'Don''t delete', 'Don''t delete');
            switch choice
                case 'Delete'
                    parent_figure = obj.GetParentFigure;
                    parent_figure.ShowWaitCursor;
                    obj.GuiCallback.BringToFront;

                    series_descriptions = obj.SeriesDescriptions;
                    
                    gui_callback = obj.GuiCallback;
                    series_uids = {};
                    
                    for series_index = 1 : numel(series_descriptions)
                        series_uids{series_index} = series_descriptions(series_index).SeriesUid;
                    end

                    % Note that obj may be deleted during this loop as the patient panels are
                    % rebuilt, so we can't reference obj at all from here on
                    % for line
                    gui_callback.DeleteFromPatientBrowser(series_uids);
                    
                    parent_figure.BringToFront;
                    parent_figure.HideWaitCursor;
                    
                case 'Don''t delete'
            end
        end
        
    end
    
    methods (Access = private)
        
        function PatientRightClicked(obj, ~, ~)
            if isempty(get(obj.PatientNameTextControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_patient = uimenu(context_menu, 'Label', 'Delete this patient', 'Callback', @obj.DeletePatientSelected);
                set(obj.PatientNameTextControl.GraphicalComponentHandle, 'uicontextmenu', context_menu);
            end
        end        
        
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