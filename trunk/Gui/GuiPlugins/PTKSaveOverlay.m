classdef PTKSaveOverlay < PTKGuiPlugin
    % PTKSaveOverlay. Gui Plugin for exporting the overlay image currently in the
    % visualisation window to a file
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKSaveOverlay is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will raise a Save dialog allowing the user to
    %     choose a filename and format, and then save the overlay image
    %     currently in the visualisation panel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Export Overlay'
        SelectedText = 'Export Overlay'
        ToolTip = 'Save the current overlay view to a file'
        Category = 'Export'
        Visibility = 'Overlay'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Icon = 'export_overlay.png'
        Location = 21
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.SaveOverlayImage;
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = false;
        end        
    end
end