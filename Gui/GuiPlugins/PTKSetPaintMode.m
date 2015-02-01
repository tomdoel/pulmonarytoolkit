classdef PTKSetPaintMode < PTKGuiPlugin
    % PTKSetPaintMode. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKSetCineTool is a Gui Plugin for the TD Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Paint'
        SelectedText = 'Paint'
        ToolTip = 'Enter paintbrush editing mode'
        Category = 'Tools'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'paint.png'
        Location = 18
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.SetControl('Paint');
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(ptk_gui_app.GetModeName, 'edit');
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = isequal(ptk_gui_app.ImagePanel.SelectedControl, 'Paint');
        end
        
    end
end