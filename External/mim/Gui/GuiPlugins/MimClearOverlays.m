classdef MimClearOverlays < MimGuiPlugin
    % MimClearOverlays. Gui Plugin for deleting overlay images in the GUI's image panel
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimClearOverlays is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will delete the overlay and quiver images
    %     displayed in the image viewer panel
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Clear'
        SelectedText = 'Clear'
        ToolTip = 'Clear the overlay'
        Category = 'Segment region'
        Visibility = 'Overlay'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'clear_overlay.png'
        Location = 0
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.DeleteOverlays;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists;
        end
    end
end