classdef MimSetPaintMode < MimGuiPlugin
    % MimSetPaintMode. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimSetPaintMode is a Gui Plugin for the MIM Toolkit. It
    %     enables segmentation editing via a paint tool
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Paint'
        SelectedText = 'Paint'
        ToolTip = 'Enter paintbrush editing mode'
        Category = 'Correction Tools'
        Visibility = 'Dataset'
        Mode = 'Edit'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'paint.png'
        Location = 22
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.SetControl('Paint');
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                (isequal(gui_app.GetCurrentModeName, 'Edit') || isequal(gui_app.GetCurrentModeName, 'ManualSegmentation')) && ...
                (isequal(gui_app.GetCurrentSubModeName, MimSubModes.EditBoundariesEditing) || isequal(gui_app.GetCurrentSubModeName, MimSubModes.FixedBoundariesEditing) || isequal(gui_app.GetCurrentSubModeName, MimSubModes.PaintEditing));
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = isequal(gui_app.ImagePanel.SelectedControl, 'Paint');
        end
        
    end
end