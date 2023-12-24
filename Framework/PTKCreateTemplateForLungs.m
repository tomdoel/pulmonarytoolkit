function template = PTKCreateTemplateForLungs(left_and_right_lung_mask, context, reporting)
    % Function for creating a template image
    % for the lung region of interest
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    template = left_and_right_lung_mask.Copy;
end