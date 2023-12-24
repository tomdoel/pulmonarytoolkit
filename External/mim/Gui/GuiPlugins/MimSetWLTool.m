classdef MimSetWLTool < MimGuiPlugin
    % MimSetWLTool. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimSetWLTool is a Gui Plugin for the MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Window / Level'
        SelectedText = 'Window / Level'
        ToolTip = 'Adjust window and level by dragging mouse over image'
        Category = 'Tools'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'windowlevel.png'
        Location = 12
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            if strcmp(gui_app.ImagePanel.Mode, MimModes.View3DMode)
                gui_app.ChangeMode([]);
            end
            gui_app.ImagePanel.SetControl('W/L');
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = strcmp(gui_app.ImagePanel.SelectedControl, 'W/L');
        end
        
    end
end