classdef TDWindowLevelSoftTissue < TDGuiPlugin
    % TDWindowLevelSoftTissue. Gui Plugin for using a preset soft tissue window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     TDWindowLevelSoftTissue is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing 
    %     panel to standard soft tissue values.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Soft Tissue'
        ToolTip = 'Changes the window and level settings to standard soft tissue values (Window 350HU Level 40HU)'
        Category = 'Window/Level Presets'

        HidePluginInDisplay = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.Window = 350;
            ptk_gui_app.ImagePanel.Level = 40;
        end
    end
end