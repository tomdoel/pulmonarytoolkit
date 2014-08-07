classdef PTKPatientNameListItem < PTKListItem
    % PTKPatientNameListItem. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPatientNameListItem represents the control showing a patient name in a
    %     PTKListBox
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Constant)
        PatientTextHeight = 18
        FontSize = 16
    end
    
    properties (Access = private)
        PatientNameText        
        PatientId
        GuiCallback
    end
    
    methods
        function obj = PTKPatientNameListItem(parent, name, visible_name, patient_id, gui_callback, reporting)
            obj = obj@PTKListItem(parent, patient_id, reporting);
            obj.TextHeight = obj.PatientTextHeight;
            
            if nargin > 0
                obj.PatientId = patient_id;
                obj.Reporting = reporting;
                obj.GuiCallback = gui_callback;

                obj.PatientNameText = PTKText(obj, visible_name, name, 'Patient');
                obj.PatientNameText.FontSize = obj.FontSize;
                obj.AddTextItem(obj.PatientNameText, reporting);
            end
        end
        
        function Resize(obj, location)
            size_changed = ~isequal(location, obj.Position);
            % Don't call the parent class
            Resize@PTKVirtualPanel(obj, location);
                        
            obj.PatientNameText.Resize(location);
            
            % A resize may change the location of the highlighted item
            if size_changed
                obj.Highlight(false);
            end
        end
        
    end
    
    methods (Access = protected)
        
        function ItemLeftClicked(obj, src, eventdata)
            ItemLeftClicked@PTKListItem(obj, src, eventdata);
            obj.GuiCallback.LoadPatient(obj.PatientId);
        end
        
        function ItemRightClicked(obj, src, eventdata)
            ItemRightClicked@PTKListItem(obj, src, eventdata);
            
            if isempty(get(obj.DescriptionControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_patient = uimenu(context_menu, 'Label', 'Delete this patient', 'Callback', @obj.DeletePatient);
                obj.SetContextMenu(context_menu);
            end
        end
        
    end
    
    methods (Access = private)
        function DeletePatient(obj, ~, ~)
            obj.GuiCallback.DeletePatient(obj.PatientId);
        end
    end
end