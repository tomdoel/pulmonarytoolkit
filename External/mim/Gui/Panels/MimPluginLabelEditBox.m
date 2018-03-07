classdef MimPluginLabelEditBox < GemLabelEditBox
    % MimPluginLabelEditBox. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimPluginLabelEditBox is used to build an edit box which
    %     interacts with the MIM GUI
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        GuiApp
        Tool
        FixToInteger = true
    end
    
    methods
        function obj = MimPluginLabelEditBox(parent, tool, icon, gui_app)
            obj = obj@GemLabelEditBox(parent, tool.ButtonText, tool.ToolTip, class(tool));
            obj.GuiApp = gui_app;
            obj.Tool = tool;
            
            [value_instance_handle, value_property_name, limits_instance_handle, limits_property_name] = tool.GetHandleAndProperty(gui_app);
            value = value_instance_handle.(value_property_name);
            
            if ~isempty(limits_property_name)
                limits = limits_instance_handle.(limits_property_name);
            end
            
            obj.EditBoxPosition = tool.EditBoxPosition;
            obj.EditBoxWidth = tool.EditBoxWidth;
            
            if ~isempty(obj.EditBox)
                obj.EditBox.SetText(num2str(value, '%.6g'));
            end
            
            obj.AddPostSetListener(value_instance_handle, value_property_name, @obj.PropertyChangedCallback);
            
            if ~isempty(limits_property_name)
                obj.AddPostSetListener(limits_instance_handle, limits_property_name, @obj.PropertyLimitsChangedCallback);
            end
        end

        function enabled = UpdateToolEnabled(obj, gui_app)
            enabled = obj.Tool.IsEnabled(gui_app);
        end
    end
    
    methods (Access = protected)
        function EditBoxCallback(obj, hObject, arg2)
            EditBoxCallback@GemLabelEditBox(obj, hObject, arg2);
            
            [instance_handle, value_property_name, ~, ~] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            
            value = round(str2double(obj.EditBox.Text));
            if obj.FixToInteger
                value = round(value);
            end
            instance_handle.(value_property_name) = value;
        end
        
        function PropertyChangedCallback(obj, ~, ~, ~)
            [instance_handle, value_property_name, ~, ~] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            value = instance_handle.(value_property_name);            
            obj.EditBox.SetText(num2str(value, '%.6g'));
        end
        
        function PropertyLimitsChangedCallback(obj, ~, ~, ~)
            [~, ~, limits_instance_handle, limits_property_name] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            limits = limits_instance_handle.(limits_property_name);            
            range = limits(2) - limits(1);
            if abs(range) >= 100
                obj.FixToInteger = true;
            else
                obj.FixToInteger = false;
            end
        end
        
    end    
end