classdef MimCapture2DImage < MimGuiPlugin
    % MimCapture2DImage. Gui Plugin for exporting the image currently in the
    % visualisation window to a file
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimCapture2DImage is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will capture the current viewer image and save
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Capture'
        SelectedText = 'Capture'
        
        ToolTip = 'Save image and overlay view to files'
        Category = 'Export'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1

        Icon = 'camera.png'
        Location = 19
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            drawnow;
            gui_app.Capture;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = false;
        end                
    end
end