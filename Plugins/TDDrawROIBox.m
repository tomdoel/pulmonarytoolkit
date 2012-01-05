classdef TDDrawROIBox < TDPlugin
    % TDDrawROIBox. Plugin to illustrate the lung region of interest by showing
    % a bounding box.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDDrawROIBox returns an overlay image corresponding to the original
    %     full-size image, with a red box drawn around the border of the region
    %     of interest, determined using the TDLungROI plugin. The box is drawn
    %     around all slices in the current orientation. The orientation is
    %     determined using the supplied TDReportingInterface.
    %
    %     When using this plugin from the gui, the contet should be changed to 
    %     show the full image before running the plugin, otherwise the bounding
    %     box will fall outside of the displayed image region of interest. The
    %     box will be draw on each slice in the current orientation of the 
    %     visualisation. If you switch to a different orientation, you will need
    %     to re-run the plugin to see the ROI box displayed for the new
    %     orientation.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Box around<BR>ROI'
        ToolTip = 'Illustrate the lung region of interest by showing the original image with a box overlay drawn around it'
        Category = 'Context'
        
        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(~, ~)
            results = [];
        end
        
        function results = GenerateImageFromResults(~, image_templates, reporting)
            results = image_templates.GetTemplateImage('OriginalImage');
            
            full_image_size = results.ImageSize;
            roi = image_templates.GetTemplateImage(TDContext.LungROI);
            origin = roi.Origin;
            image_size = roi.ImageSize;
            tl = origin - [1 1 1];
            br = origin + image_size;
            tl = max(tl, [1 1 1]);
            br = min(br, full_image_size);
            
            orientation = reporting.GetOrientation;
            
            overlay = zeros(full_image_size, 'uint8');
            
            switch orientation
                case TDImageOrientation.Coronal
                    overlay(:, tl(2):br(2), tl(3)) = 3;
                    overlay(:, tl(2):br(2), br(3)) = 3;
                    overlay(:, tl(2), tl(3):br(3)) = 3;
                    overlay(:, br(2), tl(3):br(3)) = 3;
                case TDImageOrientation.Sagittal

                    overlay(tl(1):br(1), :, tl(3)) = 3;
                    overlay(tl(1):br(1), :, br(3)) = 3;
                    overlay(tl(1), :, tl(3):br(3)) = 3;
                    overlay(br(1), :, tl(3):br(3)) = 3;
                case TDImageOrientation.Axial
                    overlay(tl(1):br(1), tl(2), :) = 3;
                    overlay(tl(1):br(1), br(2), :) = 3;
                    overlay(tl(1), tl(2):br(2), :) = 3;
                    overlay(br(1), tl(2):br(2), :) = 3;
            end
            
            results.ImageType = TDImageType.Colormap;
            results.ChangeRawImage(overlay);
        end        
    end
end