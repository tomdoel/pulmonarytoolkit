function rgb_image = PTKLabel2Rgb(label_image)
    % PTKLabel2Rgb. Converts a label image to an RGB image using the PTK
    % defauult colorscheme
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    adjusted_colourmap = [[0,0,0]; PTKSoftwareInfo.Colormap];
    label_image_adjusted = 2 + mod(label_image - 1, 63);
    label_image_adjusted(label_image == 0) = 1;
    rgb_image = label2rgb(label_image_adjusted, adjusted_colourmap);
end
