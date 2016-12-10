classdef MimZeroIsTransparent < MimGuiPlugin
    % MimZeroIsTransparent. Gui Plugin for switching transparency of zero
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimZeroIsTransparent is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        Location = 11
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.BlackIsTransparent = ~gui_app.ImagePanel.BlackIsTransparent;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.BlackIsTransparent;
        end
    end
end