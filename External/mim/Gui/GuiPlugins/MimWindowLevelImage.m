classdef MimWindowLevelImage < MimGuiPlugin
    % MimWindowLevelImage. Gui Plugin for setting the window/level to
    % image-defined values
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimWindowLevelImage is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing 
    %     panel to values specified by DICOM tages WindowCenter and WindowWidth.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Image'
        SelectedText = 'Image'
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
        function RunGuiPlugin(gui_app)
            background_image = gui_app.ImagePanel.BackgroundImage;
            if isa(background_image, 'PTKDicomImage')
                gui_app.ImagePanel.Window = gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowWidth(1);
                gui_app.ImagePanel.Level = gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowCenter(1);
            end
        end

        function enabled = IsEnabled(gui_app)
            background_image = gui_app.ImagePanel.BackgroundImage;
            enabled = gui_app.IsDatasetLoaded && gui_app.IsCT && ~strcmp(gui_app.ImagePanel.Mode, MimModes.View3DMode) && isa(background_image, 'PTKDicomImage') && isfield(background_image.MetaHeader, 'WindowWidth') && isfield(background_image.MetaHeader, 'WindowCenter');
        end
        
        function is_selected = IsSelected(gui_app)
            background_image = gui_app.ImagePanel.BackgroundImage;
            if isa(background_image, 'PTKDicomImage') && isfield(background_image.MetaHeader, 'WindowWidth') && isfield(background_image.MetaHeader, 'WindowCenter')
                is_selected = isfield(gui_app.ImagePanel.BackgroundImage.MetaHeader, 'WindowWidth') && gui_app.ImagePanel.Window == gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowWidth(1) && gui_app.ImagePanel.Level == gui_app.ImagePanel.BackgroundImage.MetaHeader.WindowCenter(1);
            else
                is_selected = false;
            end
        end
        
    end
end