classdef MimView3D < MimGuiPlugin
    % MimView3D. Gui Plugin for rendering the current overlay image in 3D 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimView3D is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing 
    %     panel to standard soft tissue values.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = '3D'
        SelectedText = '3D'        
        ToolTip = 'Visualise the current overlay in 3D'
        Category = 'View'
        Visibility = 'Overlay'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        
        Icon = 'view3d.png'
        Location = 6
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            
            % For airway-like segmentations (thin structures), we use a different set of
            % visualisation parameters
            current_name = gui_app.GetCurrentPluginName();
            if isempty(current_name)
                current_name = gui_app.CurrentSegmentationName();
            end
            gui_app.ChangeMode(MimModes.View3DMode);

            new_label = ['MIM3D-' current_name];
            render_panel = gui_app.GetRenderPanel;
            current_label = render_panel.VisualisationLabel;
            if ~isempty(current_name) && ~strcmp(current_label, new_label)
                render_panel.Clear;

                switch current_name
                    case {'PTKAirways', 'PTKAirwaysLabelledByBronchus', 'PTKAirwaysLabelledByLobe', ...
                    'PTKAirwaysPrunedBySegment', 'PTKSegmentalBronchi', 'PTKVesselness', 'PTKPrunedAirways', ...
                    'PTKPrunedAirwaysByLobe', 'PTKAirwaysSimplePrunedImage'}
                        airways = true;
                    otherwise
                        airways = false;
                end

                segmentation = gui_app.ImagePanel.OverlayImage.Copy;
                if segmentation.ImageExists
                    if airways
                        if isa(segmentation.RawImage, 'single') || isa(segmentation.RawImage, 'double')
                            segmentation.ChangeRawImage(3*uint8(segmentation.RawImage > 1));
                            smoothing_size = 0.5;
                        else
                            smoothing_size = 0.5;
                        end
                    else
                        if segmentation.ImageExists
                            if isa(segmentation.RawImage, 'single') || isa(segmentation.RawImage, 'double')
                                segmentation.ChangeRawImage(3*uint8(segmentation.RawImage > 0.1));
                                smoothing_size = 0; % Don't smooth for small structures
                            else
                                smoothing_size = 4; % 4 is good for lobes
                            end

                        end
                    end
                    limit_to_one_component_per_index = false;
                    minimum_component_volume_mm3 = 0;

                    MimVisualiseIn3D(render_panel.GetRenderAxes.GetContainerHandle, segmentation, smoothing_size, airways, limit_to_one_component_per_index, minimum_component_volume_mm3, gui_app.GetAppDef.GetDefaultColormap, gui_app.GetReporting);
                    render_panel.SetVisualisationLabel(new_label);
                end
            end
        end
        
        function enabled = IsEnabled(gui_app)
            current_name = gui_app.GetCurrentPluginName();
            current_seg_name = gui_app.CurrentSegmentationName();
            enabled = gui_app.IsDatasetLoaded() && gui_app.ImagePanel.OverlayImage.ImageExists() && (~isempty(current_name) || ~isempty(current_seg_name));
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = strcmp(gui_app.ImagePanel.Mode, char(MimModes.View3DMode));
        end        
    end
end