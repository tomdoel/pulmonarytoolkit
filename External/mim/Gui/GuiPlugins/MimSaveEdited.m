classdef MimSaveEdited < MimGuiPlugin
    % MimSaveEdited.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Save Edits'
        SelectedText = 'Save Edits'
        ToolTip = ''
        Category = 'Save / load edits'
        Visibility = 'Overlay'
        Mode = 'Edit'

        Icon = 'save.png'
        Location = 24

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.GetMode.SaveEdit;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(gui_app.GetCurrentModeName, MimModes.EditMode) && gui_app.IsTabEnabled('Edit');
        end
                
    end
end