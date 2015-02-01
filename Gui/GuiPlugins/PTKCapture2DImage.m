classdef PTKCapture2DImage < PTKGuiPlugin
    % PTKCapture2DImage. Gui Plugin for exporting the image currently in the
    % visualisation window to a file
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKSaveImage is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will raise a Save dialog allowing the user to
    %     choose a filename and format, and then save the image currently in the
    %     visualisation panel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        function RunGuiPlugin(ptk_gui_app)
            drawnow;
            ptk_gui_app.Capture;
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = false;
        end                
    end
end