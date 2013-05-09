function template = PTKCreateTemplateForSingleLung(left_and_right_lung_mask, context, reporting)
    % PTKCreateTemplateForLungROI. Function for creating a template image
    %     for the lung region of interest for the left or right lung.
    %
    %     PTKCreateTemplateForSingleLung uses the result of the plugin
    %     PTKLeftAndRightLungs (which should be passed in as the parameter
    %     left_and_right_lung_mask) to segment
    %     the left and right lungs, then calls the library function
    %     PTKGetLungROIFromLeftAndRightLungs to extract the region of interest
    %     for the left or right lung    
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    template = PTKGetLungROIFromLeftAndRightLungs(left_and_right_lung_mask, context, reporting);
end