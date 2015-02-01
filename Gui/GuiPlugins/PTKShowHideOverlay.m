classdef PTKShowHideOverlay < PTKGuiPlugin
    % PTKShowHideOverlay. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKShowHiPTKShowHideOverlaydeImage is a Gui Plugin for the TD Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Show Overlay'
        SelectedText = 'Hide Overlay'        
        ToolTip = 'Shows or hides the overlay segmentation image'
        Category = 'Show / Hide'
        Visibility = 'Dataset'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'show_overlay.png'
        Location = 8
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.ShowOverlay = ~ptk_gui_app.ImagePanel.ShowOverlay;
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = ptk_gui_app.ImagePanel.ShowOverlay;
        end
    end
end