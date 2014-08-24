classdef PTKNamePanel < PTKPanel
    % PTKNamePanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKNamePanel shows the name of the current patient, dataset, segmentatin
    %     overlay and whether the result has been edited
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)
        PatientNameText
        PatientDetailsText
        CurrentPatientId
        CurrentPatientVisibleName
        
        Gui
        GuiState
        Settings
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
        function obj = PTKNamePanel(parent, gui, settings, gui_state, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.Gui = gui;
            obj.GuiState = gui_state;
            obj.Settings = settings;
            
            obj.PatientNameText = PTKText(obj, obj.NoPatientText, '', 'PatientName');
            obj.PatientNameText.FontSize = obj.PatientNameFontSize;
            obj.PatientNameText.Bold = true;
            obj.PatientNameText.HorizontalAlignment = 'center';
            obj.AddChild(obj.PatientNameText, obj.Reporting);
            
            obj.PatientDetailsText = PTKText(obj, 'No details', '', 'PatientDetails');
            obj.PatientDetailsText.FontSize = obj.PatientDetailsFontSize;
            obj.PatientDetailsText.HorizontalAlignment = 'center';
            obj.AddChild(obj.PatientDetailsText, obj.Reporting);

            % Add listener for changes to the loaded series
            obj.AddEventListener(obj.GuiState, 'SeriesUidChangedEvent', @obj.SeriesChanged);
            
            % Add listener for changes to the loaded series
            obj.AddEventListener(obj.GuiState, 'PluginChangedEvent', @obj.PluginChanged);
        end
        
        function UpdateSeriesAndPlugin(obj)
            
            if isempty(obj.GuiState.CurrentVisiblePluginName)
                plugin_prefix = '';
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
        
        
        function CreateGuiComponent(obj, panel_position, reporting)
            CreateGuiComponent@PTKPanel(obj, panel_position, reporting);
        end
        
        function Resize(obj, panel_position)
            Resize@PTKPanel(obj, panel_position);
            
            componenent_width = panel_position(3) - obj.LeftMargin - obj.RightMargin;

            patient_name_y = panel_position(4) - obj.TopMargin - obj.PatientNameHeight;
            patient_details_y = patient_name_y - obj.VerticalSpacing - obj.PatientDetailsHeight;
            
            obj.PatientNameText.Resize([obj.LeftMargin, patient_name_y, componenent_width, obj.PatientNameHeight]);
            obj.PatientDetailsText.Resize([obj.LeftMargin, patient_details_y, componenent_width, obj.PatientDetailsHeight]);
        end
        
        function height = GetRequestedHeight(obj, width)            
            height = obj.TopMargin + obj.PatientNameHeight + obj.PatientDetailsHeight + obj.BottomMargin + obj.VerticalSpacing;
        end
        
    end
    
    methods (Access = private)
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