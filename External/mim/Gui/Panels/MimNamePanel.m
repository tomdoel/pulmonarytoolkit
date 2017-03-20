classdef MimNamePanel < GemPanel
    % MimNamePanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimNamePanel shows the name of the current patient, dataset, segmentatin
    %     overlay and whether the result has been edited
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    

    properties (Access = private)
        PatientNameText
        PatientDetailsText
        CurrentPatientId
        CurrentPatientVisibleName
        
        Gui
        GuiState
    end
    
    properties (Constant, Access = private)
        TopMargin = 5
        LeftMargin = 5
        RightMargin = 5
        BottomMargin = 8
        VerticalSpacing = 3
        
        NoPatientText = 'No patient loaded'
        
        PatientNameHeight = 15
        PatientDetailsHeight = 15
        PatientNameFontSize = 14
        PatientDetailsFontSize = 12
    end
    
    methods
        function obj = MimNamePanel(parent, gui, gui_state)
            obj = obj@GemPanel(parent);
            
            obj.Gui = gui;
            obj.GuiState = gui_state;
            
            obj.BottomBorder = true;
            
            obj.PatientNameText = GemText(obj, obj.NoPatientText, '', 'PatientName');
            obj.PatientNameText.FontSize = obj.PatientNameFontSize;
            obj.PatientNameText.Bold = true;
            obj.PatientNameText.HorizontalAlignment = 'center';
            obj.AddChild(obj.PatientNameText);
            
            obj.PatientDetailsText = GemText(obj, 'No details', '', 'PatientDetails');
            obj.PatientDetailsText.FontSize = obj.PatientDetailsFontSize;
            obj.PatientDetailsText.HorizontalAlignment = 'center';
            obj.AddChild(obj.PatientDetailsText);

            % Add listener for changes to the loaded patient
            obj.AddEventListener(obj.GuiState, 'PatientIdChangedEvent', @obj.PatientChanged);
            
            % Add listener for changes to the loaded series
            obj.AddEventListener(obj.GuiState, 'SeriesUidChangedEvent', @obj.SeriesChanged);
            
            % Add listener for changes to the loaded series
            obj.AddEventListener(obj.GuiState, 'PluginChangedEvent', @obj.PluginChanged);
        end
        
        function UpdateSeriesAndPlugin(obj)
            
            if isempty(obj.GuiState.CurrentVisiblePluginName)
                if ~isempty(obj.GuiState.CurrentSegmentationName)
                    plugin_prefix = [obj.GuiState.CurrentSegmentationName ' (manual segmentation)' , ' - '];
                else
                    plugin_prefix = '';
                end
            else
                if obj.GuiState.CurrentPluginResultIsEdited
                    edited_line = 'Edited ';
                else
                    edited_line = '';
                end
                plugin_prefix = [edited_line, obj.GuiState.CurrentVisiblePluginName ' - '];
            end
            
            subtitle = [plugin_prefix, obj.GuiState.CurrentSeriesName];
            
            obj.PatientDetailsText.ChangeText(subtitle);
        end
        
        
        function CreateGuiComponent(obj, panel_position)
            CreateGuiComponent@GemPanel(obj, panel_position);
        end
        
        function Resize(obj, panel_position)
            Resize@GemPanel(obj, panel_position);
            
            componenent_width = panel_position(3) - obj.LeftMargin - obj.RightMargin;

            patient_name_y = 1 + panel_position(4) - obj.TopMargin - obj.PatientNameHeight;
            patient_details_y = patient_name_y - obj.VerticalSpacing - obj.PatientDetailsHeight;
            
            obj.PatientNameText.Resize([1 + obj.LeftMargin, patient_name_y, componenent_width, obj.PatientNameHeight]);
            obj.PatientDetailsText.Resize([1 + obj.LeftMargin, patient_details_y, componenent_width, obj.PatientDetailsHeight]);
        end
        
        function height = GetRequestedHeight(obj, width)            
            height = obj.TopMargin + obj.PatientNameHeight + obj.PatientDetailsHeight + obj.BottomMargin + obj.VerticalSpacing;
        end
        
    end
    
    methods (Access = private)
        function PatientChanged(obj, ~, ~)
            % This event fires when the loaded patient has been changed.
            
            if ~strcmp(obj.GuiState.CurrentPatientVisibleName, obj.CurrentPatientVisibleName)
                obj.CurrentPatientVisibleName = obj.GuiState.CurrentPatientVisibleName;
                
                if isempty(obj.CurrentPatientVisibleName)
                    patient_name = obj.NoPatientText;
                else
                    patient_name = obj.CurrentPatientVisibleName;
                end
                
                obj.PatientNameText.ChangeText(patient_name);
            end
            obj.UpdateSeriesAndPlugin;
        end
        
        function SeriesChanged(obj, ~, ~)
            % This event fires when the loaded series has been changed.
            
            if ~strcmp(obj.GuiState.CurrentPatientVisibleName, obj.CurrentPatientVisibleName)
                obj.CurrentPatientVisibleName = obj.GuiState.CurrentPatientVisibleName;
                
                if isempty(obj.CurrentPatientVisibleName)
                    patient_name = obj.NoPatientText;
                else
                    patient_name = obj.CurrentPatientVisibleName;
                end
                
                obj.PatientNameText.ChangeText(patient_name);
            end
            obj.UpdateSeriesAndPlugin;
        end
        
        function PluginChanged(obj, ~, ~)
            obj.UpdateSeriesAndPlugin;
        end
    end
end