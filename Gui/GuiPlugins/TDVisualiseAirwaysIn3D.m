classdef TDVisualiseAirwaysIn3D < TDGuiPlugin
    % TDVisualiseAirwaysIn3D. Gui Plugin for rendering the current overlay image in 3D 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     TDVisualiseAirwaysIn3D is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will create a new figure and display the current
    %     image overlay as a 3D image. If the image is integer-bsed, it is
    %     treated as a colormap, where non-zero values are rendered according to
    %     the colours in the Lines colourmap. Floating-point images are rendered
    %     in a single colour where any values greater than a threshold are
    %     rendered.
    %
    %     This plugin is intended to visualise thin structures such as small
    %     airways. For larger structrues such as lobes, a better visual
    %     appearance can be obtained usint the TDVisualiseSegmentationIn3D gui
    %     plugin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    


    properties
        ButtonText = '3D Airways'
        ToolTip = 'Visualise the current overlay in 3D'
        Category = 'View'

        HidePluginInDisplay = false
        TDPTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            segmentation = ptk_gui_app.ImagePanel.OverlayImage.Copy;
            if segmentation.ImageExists
                segmentation.ChangeRawImage(uint8(segmentation.RawImage == 1));
                
                if segmentation.ImageExists
                    if isa(segmentation.RawImage, 'single') || isa(segmentation.RawImage, 'double')
                        segmentation = segmentation.Copy;
                        segmentation.ChangeRawImage(3*uint8(segmentation.RawImage > 1));
                        smoothing_size = 0.5;
                    else
                        smoothing_size = 0.5;
                    end
                    
                    TDVisualiseIn3D([], segmentation, smoothing_size, true, ptk_gui_app.Reporting);
                end
            end
        end
    end
end