classdef MimSaveOverlay < MimGuiPlugin
    % MimSaveOverlay. Gui Plugin for exporting the overlay image currently in the
    % visualisation window to a file
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Export Overlay'
        SelectedText = 'Export Overlay'
        ToolTip = 'Save the current overlay view to a file'
        Category = 'Segmentation display'
        Visibility = 'Overlay'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Icon = 'export_overlay.png'
        Location = 14
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