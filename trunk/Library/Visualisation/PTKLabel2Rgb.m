function rgb_image = PTKLabel2Rgb(label_image)
    % PTKLabel2Rgb. Converts a label image to an RGB image using the PTK
    % defauult colorscheme
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    label_image = 1 + mod(label_image - 1, 63);    
    rgb_image = label2rgb(label_image, PTKSoftwareInfo.Colormap);
end
