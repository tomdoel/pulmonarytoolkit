classdef PTKSetEditBorderMode < PTKGuiPlugin
    % PTKSetEditBorderMode.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Edit Boundary'
        SelectedText = 'Edit Boundary'
        ToolTip = 'Modify the boundary of a segmented object by clicking on new boundary points'
        Category = 'Tools'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'edit_boundary.png'
        Location = 17
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.SetControl('Edit');
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(ptk_gui_app.GetModeName, 'edit');
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = isequal(ptk_gui_app.ImagePanel.SelectedControl, 'edit');
        end
        
    end
end