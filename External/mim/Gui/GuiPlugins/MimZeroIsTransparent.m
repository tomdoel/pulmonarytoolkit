classdef MimZeroIsTransparent < MimGuiPlugin
    % MimZeroIsTransparent. Gui Plugin for switching transparency of zero
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimZeroIsTransparent is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Show zero transparent'
        SelectedText = 'Show zero as black'
        ToolTip = 'Changes whether zero values in the overlay are shown as black or transparent'
        Category = 'Segmentation display'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'show_black.png'
        Location = 24
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.BlackIsTransparent = ~gui_app.ImagePanel.BlackIsTransparent;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ~strcmp(gui_app.ImagePanel.Mode, MimModes.View3DMode) && gui_app.ImagePanel.ShowOverlay;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.BlackIsTransparent;
        end
    end
end