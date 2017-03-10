classdef MimEditYellow < MimGuiPlugin
    % MimEditYellow. Gui Plugin for switching transparency of zero
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimEditYellow is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Yellow'
        SelectedText = 'Yellow'
        ToolTip = 'Edit with yellow label'
        Category = 'Segmentation label'
        Visibility = 'Dataset'
        Mode = 'Edit'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'paint.png'
        IconColour = GemMarkerPoint.DefaultColours{6}
        Location = 36
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.PaintBrushColour = 6;
        end
        
        function enabled = IsEnabled(gui_app)
             enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(gui_app.ImagePanel.SelectedControl, 'Paint');
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.PaintBrushColour == 6;
        end
    end
end