classdef MimEnterEditMode < MimGuiPlugin
    % MimEnterEditMode. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimEnterEditMode is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Correct'
        SelectedText = 'Correct'
        ToolTip = 'Enter correction mode where you can edit the segmented result'
        Category = 'Correct'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'edit.png'
        Location = 20
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ChangeMode(MimModes.EditMode);
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                ~isequal(gui_app.GetCurrentModeName, MimModes.EditMode) && gui_app.IsTabEnabled('Edit');
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = isequal(gui_app.ImagePanel.SelectedControl, 'Edit');
        end
        
    end
end