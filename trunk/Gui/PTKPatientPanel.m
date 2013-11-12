classdef PTKPatientPanel < PTKPanel
    % PTKPatientPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the PUlmonary Toolkit to help
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
    
    properties (SetAccess = private)
        Name
        Id
    end

    properties (Access = private)
        PatientDetails
        PatientNameTextControl
        StudyListTable
        CachedTableSize
    end
    
    properties (Constant, Access = private)
        PatientNameFontSize = 40
        PatientNameHeight = 40
        PatientNameWidth = 200
        StudyFontSize = 20
        StudyTableSizePerDataset = 23
        StudyTableHeightAdd = 4;
        BorderSpace = 10;
        MinDescriptionWidth = 100
        ModalityWidth = 50
        DateWidth = 100
        NumImagesWidth = 150
        TableSpacing = 4
    end
    
    methods
        function obj = PTKPatientPanel(parent, patient_details, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.PatientDetails = patient_details;
            obj.Name = patient_details.Name;
            obj.Id = patient_details.Id;
            obj.PatientNameTextControl = uicontrol('Style', 'text', 'Parent', obj.PanelHandle, 'Units', 'pixels', 'FontSize', obj.PatientNameFontSize, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white', 'HorizontalAlignment', 'left');
            set(obj.PatientNameTextControl, 'String', obj.Name);
            obj.StudyListTable = uitable('Parent', obj.PanelHandle, 'Units', 'pixels', ...
               'FontSize', obj.StudyFontSize, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white');
            obj.AddStudies;
            patient_name_position_y = 1 + obj.GetRequestedHeight - obj.PatientNameHeight - obj.BorderSpace;
            set(obj.PatientNameTextControl, 'Position', [1 patient_name_position_y obj.PatientNameWidth obj.PatientNameHeight]);
        end
        
        function Resize(obj, new_position)
            study_table_position = [1 obj.BorderSpace new_position(3) new_position(4)-obj.PatientNameHeight-2*obj.BorderSpace];
            column_widths = obj.GetColumnWidths(new_position(3));
            set(obj.StudyListTable, 'Units', 'Pixels', 'Position', study_table_position, 'ColumnWidth', column_widths);
            Resize@PTKPanel(obj, new_position);
        end
        
        function height = GetRequestedHeight(obj)
            height = obj.PatientNameHeight + obj.CachedTableSize(2) + 2*obj.BorderSpace;
        end
    end
    methods (Access = private)
        
        function column_widths = GetColumnWidths(obj, panel_width)
            description_width = max(obj.MinDescriptionWidth, panel_width - obj.ModalityWidth - obj.DateWidth - obj.NumImagesWidth - obj.TableSpacing);
            column_widths = [description_width, obj.ModalityWidth, obj.DateWidth, obj.NumImagesWidth];
            total_width = sum(column_widths);
            adjustment = ceil(abs(total_width - panel_width)/4);
            column_widths = column_widths - adjustment;
            column_widths = num2cell(column_widths);
        end
        
        function AddStudies(obj)
            datasets = obj.PatientDetails.GetDatasets;
            data = {};
            for study_index = 1 : length(datasets)
                study = datasets{study_index};
                data{study_index, 1} = [study.SeriesDescription '/' study.StudyDescription];
                data{study_index, 2} = study.Modality;
                data{study_index, 3} = study.Date;
                data{study_index, 4} = [int2str(study.NumOfImages) ' images'];
            end
            set(obj.StudyListTable, 'Data', data, 'ColumnName', [], 'RowName', []);
            table_extent = get(obj.StudyListTable, 'Extent');
            obj.CachedTableSize = table_extent(3 : 4);
        end
    end    
end