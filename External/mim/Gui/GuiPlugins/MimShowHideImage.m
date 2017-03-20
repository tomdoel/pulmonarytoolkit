classdef MimShowHideImage < MimGuiPlugin
    % MimShowHideImage. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimShowHideImage is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Show Image'
        SelectedText = 'Hide Image'
        ToolTip = 'Shows or hides the background image'
        Category = 'Show / hide'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'show_image.png'
        Location = 7
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.ShowImage = ~gui_app.ImagePanel.ShowImage;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && ~strcmp(gui_app.ImagePanel.Mode, MimModes.View3DMode);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.ShowImage;
        end
    end
end