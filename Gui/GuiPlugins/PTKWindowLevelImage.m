classdef PTKWindowLevelImage < PTKGuiPlugin
    % PTKWindowLevelImage. Gui Plugin for setting the window/level to
    % image-defined values
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKWindowLevelImage is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing 
    %     panel to values specified by DICOM tages WindowCenter and WindowWidth.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Image'
        ToolTip = 'Changes the window and level settings to values specified in the image'
        Category = 'Window/Level Presets'
        Visibility = 'Dataset'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.Window = ptk_gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowWidth(1);
            ptk_gui_app.ImagePanel.Level = ptk_gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowCenter(1);
        end
    end
end