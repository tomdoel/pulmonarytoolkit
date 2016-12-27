classdef MimWindowLevelLung < MimGuiPlugin
    % MimWindowLevelLung. Gui Plugin for using a preset lung window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimWindowLevelLung is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing
    %     panel to standard lung values.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Lung preset'
        SelectedText = 'Lung preset'
        ToolTip = 'Changes the window and level settings to standard lung values (Window 1600HU Level -600HU)'
        Category = 'Window/Level Presets'
        Visibility = 'Dataset'
        Mode = 'Toolbar'
        
        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'wl_lung.png'
        Location = 21
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.Window = 1600;
            gui_app.ImagePanel.Level = -600;
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.IsCT && ~strcmp(gui_app.ImagePanel.Mode, MimModes.View3DMode);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.Window == 1600 && gui_app.ImagePanel.Level == -600;
        end
    end
end