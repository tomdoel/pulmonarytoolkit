classdef PTKVisualiseSegmentationIn3D < PTKGuiPlugin
    % PTKVisualiseSegmentationIn3D. Gui Plugin for rendering the current overlay image in 3D 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKVisualiseSegmentationIn3D is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will create a new figure and display the current
    %     image overlay as a 3D image. If the image is integer-bsed, it is
    %     treated as a colormap, where non-zero values are rendered according to
    %     the colours in the Lines colourmap. Floating-point images are rendered
    %     in a single colour where any values greater than a threshold are
    %     rendered.
    %
    %     This plugin performs smoothing and morphological operations to
    %     improve the appearance of the 3D rendering. This may remove small
    %     structures such as small airways from the rendered image. To visualise
    %     these structures use the gui plugin PTKVisualiseAirwaysIn3D.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = '3D'
        ToolTip = 'Visualise the current overlay in 3D'
        Category = 'View'
        Visibility = 'Overlay'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            segmentation = ptk_gui_app.ImagePanel.OverlayImage.Copy;
            
            if segmentation.ImageExists
                if isa(segmentation.RawImage, 'single') || isa(segmentation.RawImage, 'double')
                    segmentation = segmentation.Copy;
                    segmentation.ChangeRawImage(3*uint8(segmentation.RawImage > 0.1));
                    smoothing_size = 0; % Don't smooth for small structures
                else
                    smoothing_size = 4; % 4 is good for lobes
                end
                
                PTKVisualiseIn3D([], segmentation, smoothing_size, false, ptk_gui_app.Reporting);
            end
        end
    end
end