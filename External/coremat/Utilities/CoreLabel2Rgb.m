function rgb_image = CoreLabel2Rgb(label_image)
    % Converts a label image to an RGB image using the default colorscheme
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    adjusted_colourmap = [[0,0,0]; CoreSystemUtilities.BackwardsCompatibilityColormap];
    label_image_adjusted = uint8(1 + mod(label_image - 1, 63));
    label_image_adjusted(label_image == 0) = 0;
    rgb_image = uint8(255*ind2rgb(label_image_adjusted, adjusted_colourmap));
end
