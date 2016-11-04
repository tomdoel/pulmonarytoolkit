classdef MimExportEditedImage < MimGuiPlugin
    % MimExportEditedImage. Gui Plugin 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimExportEditedImage is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Export Corrections'
        SelectedText = 'Export Corrections'
        ToolTip = 'Exports the current edit to an external file'
        Category = 'Save / load corrections'
        Visibility = 'Overlay'
        Mode = 'Edit'

        Icon = 'export_overlay.png'
        Location = 28

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.GetMode.ExportEdit;
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(ptk_gui_app.GetCurrentModeName, MimModes.EditMode) && ptk_gui_app.IsTabEnabled('Edit');
        end                
    end
end