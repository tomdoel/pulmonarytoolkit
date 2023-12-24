classdef MimPluginLabelButton < GemLabelButton
    % MimPluginLabelButton. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimPluginLabelButton is used to build a button control which activates a tool
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        Tool
        Callback
    end
    
    methods
        function obj = MimPluginLabelButton(parent, tool, icon, callback)
            obj = obj@GemLabelButton(parent, tool.ButtonText, tool.ToolTip, class(tool), icon);
            obj.Tool = tool;
            obj.Callback = callback;
        end

        function enabled = UpdateToolEnabled(obj, gui_app)
            enabled = obj.Tool.IsEnabled(gui_app);
            selected = obj.Tool.IsSelected(gui_app);
            obj.Select(selected);

            % If the tool defines SelectedText then it has special behaviour - different text
            % for selected or unselected
            if selected && isprop(obj.Tool, 'SelectedText')
                obj.Text.ChangeText(obj.Tool.SelectedText);
            else
                obj.Text.ChangeText(obj.Tool.ButtonText);
            end
        end
    end
    
    methods (Access = protected)
        function ButtonClickedCallback(obj, plugin_name)
            ButtonClickedCallback@GemLabelButton(obj, plugin_name);
            
            obj.Callback(obj.Tag);
        end
    end    
end