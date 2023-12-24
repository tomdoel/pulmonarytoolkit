classdef MimSetRemapMode < MimGuiPlugin
    % MimSetRemapMode. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimSetRemapMode is a Gui Plugin for the MIM Toolkit. It
    %     enabled an edit mode where colour labels can be remapped
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Remap'
        SelectedText = 'Remap'
        ToolTip = 'Enter colour remapping editing mode'
        Category = 'Correction Tools'
        Visibility = 'Dataset'
        Mode = 'Edit'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'edit_boundary.png'
        Location = 23
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.SetControl('Map');
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                (isequal(gui_app.GetCurrentModeName, 'Edit') || isequal(gui_app.GetCurrentModeName, 'ManualSegmentation')) && ...
                (isequal(gui_app.GetCurrentSubModeName, MimSubModes.ColourRemapEditing));
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = isequal(gui_app.ImagePanel.SelectedControl, 'Map');
        end
        
    end
end