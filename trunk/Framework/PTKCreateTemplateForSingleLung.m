function template = PTKCreateTemplateForSingleLung(left_or_right_lung_mask, context, reporting)
    % PTKCreateTemplateForLungROI. Function for creating a template image
    %     for the lung region of interest for the left or right lung.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    template = left_or_right_lung_mask.Copy;
end