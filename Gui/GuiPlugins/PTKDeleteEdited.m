classdef PTKDeleteEdited < PTKGuiPlugin
    % PTKDeleteEdited.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Delete all corrections'
        SelectedText = 'Delete all corrections'
        ToolTip = ''
        Category = 'Save / load corrections'
        Visibility = 'Overlay'
        Mode = 'Edit'
        Icon = 'bin.png'
        Location = 25
        
        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            
            % ToDo
            ptk_gui_app.GetMode.DeleteAllEditsWithPrompt;
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists && ...
                ~isequal(ptk_gui_app.GetCurrentModeName, PTKModes.EditMode) && ptk_gui_app.IsTabEnabled('Edit');
        end
        
    end
end