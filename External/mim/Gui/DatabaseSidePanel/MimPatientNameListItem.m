classdef MimPatientNameListItem < GemListItem
    % MimPatientNameListItem. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimPatientNameListItem represents the control showing a patient name in a
    %     GemListBox
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Constant)
        PatientTextHeight = 21
        FontSize = 14
    end
    
    properties (Access = private)
        PatientNameText        
        PatientId
        GuiCallback
    end
    
    methods
        function obj = MimPatientNameListItem(parent, name, visible_name, patient_id, gui_callback)
            obj = obj@GemListItem(parent, patient_id);
            obj.TextHeight = obj.PatientTextHeight;
            
            if nargin > 0
                obj.PatientId = patient_id;
                obj.GuiCallback = gui_callback;

                obj.PatientNameText = GemText(obj, visible_name, name, 'Patient');
                obj.PatientNameText.FontSize = obj.FontSize;
                obj.AddTextItem(obj.PatientNameText);
            end
        end
        
        function Resize(obj, location)
            size_changed = ~isequal(location, obj.Position);
            % Don't call the parent class
            Resize@GemVirtualPanel(obj, location);
                        
            obj.PatientNameText.Resize(location);
            
            % A resize may change the location of the highlighted item
            if size_changed
                obj.Highlight(false);
            end
        end
        
    end
    
    methods (Access = protected)
        
        function ItemLeftClicked(obj, src, eventdata)
            ItemLeftClicked@GemListItem(obj, src, eventdata);
            obj.GuiCallback.PatientClicked(obj.PatientId);
        end
        
        function ItemRightClicked(obj, src, eventdata)
            ItemRightClicked@GemListItem(obj, src, eventdata);
            
            if isempty(get(obj.PatientNameText.GraphicalComponentHandle, 'uicontextmenu'))
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