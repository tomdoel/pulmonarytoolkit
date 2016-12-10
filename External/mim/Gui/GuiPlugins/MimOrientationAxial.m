classdef MimOrientationAxial < MimGuiPlugin
    % MimOrientationAxial. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimOrientationAxial is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing 
    %     panel to standard soft tissue values.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Axial View'
        SelectedText = 'Axial View'
        ToolTip = 'Changes the image orientation to a axial view'
        Category = 'View'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'axial_thumb.png'
        Location = 5
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.Orientation = PTKImageOrientation.Axial;
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.Orientation == PTKImageOrientation.Axial;
        end
    end
end