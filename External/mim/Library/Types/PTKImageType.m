classdef PTKImageType
    % PTKImageType. An enumeration used to specify how an image should be displayed
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    enumeration
        Grayscale,  % Image is a 16-bit integer greyscale image
        Colormap,   % Image is an 8-bit integer colormap, using the Lines colormap
        Scaled,     % Image is a single-colour floating point and will be scaled between its minimum and maximum values
        Quiver      % Image is a quiver plot; each voxel has 3 component values defining a 3D vector
    end
    
end

