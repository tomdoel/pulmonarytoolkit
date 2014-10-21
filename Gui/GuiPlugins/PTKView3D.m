classdef PTKView3D < PTKGuiPlugin
    % PTKGuiPlugin. Gui Plugin for rendering the current overlay image in 3D 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTK3DTool is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will change the window and level of the viewing 
    %     panel to standard soft tissue values.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = '3D'
        SelectedText = '3D'        
        ToolTip = 'Visualise the current overlay in 3D'
        Category = 'View'
        Visibility = 'Overlay'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Icon = 'seg_lobes.tif'
        Location = 6
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            
            % For airway-like segmentations (thin structures), we use a different set of
            % visualisation parameters
            current_name = ptk_gui_app.GetCurrentPluginName;
            switch current_name
                case {'PTKAirways', 'PTKAirwaysLabelledByBronchus', 'PTKAirwaysLabelledByLobe', ...
                'PTKAirwaysPrunedBySegment', 'PTKSegmentalBronchi', 'PTKVesselness', 'PTKPrunedAirways', ...
                'PTKPrunedAirwaysByLobe'}
                    airways = true;
                otherwise
                    airways = false;
            end
            
            segmentation = ptk_gui_app.ImagePanel.OverlayImage.Copy;
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
                
                PTKVisualiseIn3D([], segmentation, smoothing_size, airways, limit_to_one_component_per_index, minimum_component_volume_mm3, ptk_gui_app.Reporting);
            end
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            current_name = ptk_gui_app.GetCurrentPluginName;
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists && ~isempty(current_name);
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = false;
        end        
    end
end