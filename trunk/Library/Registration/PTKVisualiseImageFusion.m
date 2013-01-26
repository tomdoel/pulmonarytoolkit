function viewer_handle = TDVisualiseImageFusion(image_1, image_2)
    % TDVisualiseImageFusion. Visualise two registered images
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    image_1 = image_1.Copy;
    image_2 = image_2.Copy;
    TDImageUtilities.MatchSizesAndOrigin(image_1, image_2);
    viewer_handle = TDViewer(image_1);
    viewer_handle.ViewerPanelHandle.OverlayImage = image_2;
end

