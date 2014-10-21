classdef PTKPluginLabelButton < PTKLabelButton
    % PTKPluginLabelButton. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPluginLabelButton is used to build a button control which activates a tool
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        GuiApp
        Tool
    end
    
    methods
        function obj = PTKPluginLabelButton(parent, tool, icon, gui_app, reporting)
            obj = obj@PTKLabelButton(parent, tool.ButtonText, tool.ToolTip, class(tool), icon, reporting);
            obj.GuiApp = gui_app;
            obj.Tool = tool;
        end

        function enabled = UpdateToolEnabled(obj, gui_app)
            enabled = obj.Tool.IsEnabled(gui_app);
            selected = obj.Tool.IsSelected(gui_app);
            obj.Select(selected);

            % If the tool defines SelectedText then it has special behaviour - different text
            % for selected or unselected
            if selected
                obj.Text.ChangeText(obj.Tool.SelectedText);
            else
                obj.Text.ChangeText(obj.Tool.ButtonText);
            end
        end
    end
    
    methods (Access = protected)
        function ButtonClickedCallback(obj, plugin_name)
            ButtonClickedCallback@PTKLabelButton(obj, plugin_name);
            obj.Tool.RunGuiPlugin(obj.GuiApp);
            obj.GuiApp.ToolClicked;
        end
    end    
end