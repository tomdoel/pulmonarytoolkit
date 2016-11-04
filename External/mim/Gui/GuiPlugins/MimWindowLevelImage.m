classdef MimWindowLevelImage < MimGuiPlugin
    % MimWindowLevelImage. Gui Plugin for setting the window/level to
    % image-defined values
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     MimWindowLevelImage is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing 
    %     panel to values specified by DICOM tages WindowCenter and WindowWidth.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Image preset'
        SelectedText = 'Image preset'
        ToolTip = 'Changes the window and level settings to values specified in the image'
        Category = 'Window/Level Presets'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'wl_image.png'
        Location = 24
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            background_image = ptk_gui_app.ImagePanel.BackgroundImage;
            if isa(background_image, 'PTKDicomImage')
                ptk_gui_app.ImagePanel.Window = ptk_gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowWidth(1);
                ptk_gui_app.ImagePanel.Level = ptk_gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowCenter(1);
            end
        end

        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.IsCT;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            background_image = ptk_gui_app.ImagePanel.BackgroundImage;
            if isa(background_image, 'PTKDicomImage')
                is_selected = isfield(ptk_gui_app.ImagePanel.BackgroundImage.MetaHeader, 'WindowWidth') && ptk_gui_app.ImagePanel.Window == ptk_gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowWidth(1) && ptk_gui_app.ImagePanel.Level == ptk_gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowCenter(1);
            else
                is_selected = false;
            end
        end
        
    end
end