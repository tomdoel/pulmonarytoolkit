classdef TDImageType
    % TDImageType. An enumeration used to specify how an image should be displayed
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    enumeration
        Grayscale,  % Image is a 16-bit integer greyscale image
        Colormap,   % Image is an 8-bit integer colormap, using the Lines colormap
        Scaled,     % Image is a single-colour floating point and will be scaled between its minimum and maximum values
        Quiver      % Image is a quiver plot; each voxel has 3 component values defining a 3D vector
    end
    
end

