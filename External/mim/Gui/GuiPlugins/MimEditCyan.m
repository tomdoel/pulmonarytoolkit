classdef MimEditCyan < MimGuiPlugin
    % MimEditCyan. Gui Plugin for setting paint colour
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimEditCyan is a Gui Plugin for the MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Cyan'
        SelectedText = 'Cyan'
        ToolTip = 'Edit with cyan label'
        Category = 'Segmentation label'
        Visibility = 'Dataset'
        Mode = 'Edit'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 5
        ButtonHeight = 1
        Icon = 'paint.png'
        IconColour = GemMarkerPoint.DefaultColours{4}
        Location = 34
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.PaintBrushColour = 4;
        end
        
        function enabled = IsEnabled(gui_app)
             enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(gui_app.ImagePanel.SelectedControl, 'Paint');
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.PaintBrushColour == 4;
        end
    end
end