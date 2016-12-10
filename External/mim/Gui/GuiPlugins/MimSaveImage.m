classdef MimSaveImage < MimGuiPlugin
    % MimSaveImage. Gui Plugin for exporting the image currently in the
    % visualisation window to a file
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimSaveImage is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will raise a Save dialog allowing the user to
    %     choose a filename and format, and then save the image currently in the
    %     visualisation panel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Export Image'
        SelectedText = 'Export Image'
        ToolTip = 'Save the current image to files'
        Category = 'Export'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Icon = 'export_image.png'
        Location = 20        
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.SaveBackgroundImage();
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = false;
        end        
    end
end