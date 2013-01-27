classdef PTKFlattenSegmentation < PTKGuiPlugin
    % PTKFlattenSegmentation. Gui Plugin for replacing the overlay with its projection on the current viewing plane
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKFlattenSegmentation is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will replace each slice of the current overlay (in
    %     the current axis orientation) with a projection image formed by
    %     combining every slice. The effect is like flattening an image and is
    %     intended for use with colormap images. It is useful for visualising
    %     segmentations such as the airway tree where the structure is more
    %     visible in certain 2D orientations.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Flatten'
        ToolTip = 'Superimpose all slices of the image'
        Category = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.OverlayImage.Flatten(ptk_gui_app.ImagePanel.Orientation);
        end
    end
end