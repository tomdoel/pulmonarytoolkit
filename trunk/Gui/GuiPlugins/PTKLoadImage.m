classdef PTKLoadImage < PTKGuiPlugin
    % PTKLoadImage. Gui Plugin for importing and loading image files.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKLoadImage is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will bring up a dialog box for selecting files to
    %     load. These files will be imported into the Pulmonary Toolkit if 
    %     necessary, and then loaded into the gui.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Load'
        ToolTip = 'Select image files to import and load'
        Category = 'File'
        Visibility = 'Always'
        Mode = 'File'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.SelectFilesAndLoad();
        end
    end
end