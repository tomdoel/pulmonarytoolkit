classdef MimSaveOverlay < MimGuiPlugin
    % MimSaveOverlay. Gui Plugin for exporting the overlay image currently in the
    % visualisation window to a file
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimSaveOverlay is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will raise a Save dialog allowing the user to
    %     choose a filename and format, and then save the overlay image
    %     currently in the visualisation panel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Export Segmentation'
        SelectedText = 'Export Segmentation'
        ToolTip = 'Save the current Segmentation overlay to a file'
        Category = 'Correct and Export'
        Visibility = 'Overlay'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        
        Icon = 'export_overlay.png'
        Location = 32
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.SaveOverlayImage;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = false;
        end        
    end
end