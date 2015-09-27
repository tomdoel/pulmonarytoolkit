classdef PTKSetRemapMode < PTKGuiPlugin
    % PTKSetRemapMode. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKSetRemapMode is a Gui Plugin for the TD Pulmonary Toolkit. It
    %     enabled an edit mode where colour labels can be remapped
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Remap'
        SelectedText = 'Remap'
        ToolTip = 'Enter colour remapping editing mode'
        Category = 'Tools'
        Visibility = 'Dataset'
        Mode = 'Edit'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'edit_boundary.png'
        Location = 3
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.SetControl('Map');
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists && ...
                (isequal(ptk_gui_app.GetCurrentModeName, 'Edit') || isequal(ptk_gui_app.GetCurrentModeName, 'ManualSegmentation')) && ...
                (isequal(ptk_gui_app.GetCurrentSubModeName, PTKSubModes.ColourRemapEditing));
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = isequal(ptk_gui_app.ImagePanel.SelectedControl, 'Map');
        end
        
    end
end