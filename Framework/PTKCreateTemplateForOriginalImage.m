function template = PTKCreateTemplateForOriginalImage(original_image, context, reporting)
    % Function for creating a template image
    % for the original loaded image before any cropping or resizing
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    template = original_image.BlankCopy();
end 
