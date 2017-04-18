classdef MimPaintOverBackground < MimGuiPlugin
    % MimPaintOverBackground. Gui Plugin for enabling or disabling developer mode
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Paint outside boundary'
        SelectedText = 'Paint within boundary'
        ToolTip = 'Determines whether painting is allowed to go beyond the boundary of the existing segmentation'
        Category = 'Paint'
        Visibility = 'Dataset'
        Mode = 'Edit'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        
        Icon = 'paint.png'
        Location = 41
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            % Toggles painting over background
            gui_app.ImagePanel.PaintOverBackground = ~gui_app.ImagePanel.PaintOverBackground;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(gui_app.ImagePanel.SelectedControl, 'Paint');
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.PaintOverBackground;
        end
    end
end