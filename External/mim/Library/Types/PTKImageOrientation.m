classdef PTKImageOrientation < uint8
    % PTKImageOrientation. An enumeration used to specify the orientation of an
    % image
    %
    %     The number values correspond to the dimension axis perpendicular to
    %     the view
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    enumeration
        Coronal (GemImageOrientation.XZ)
        Sagittal (GemImageOrientation.YZ)
        Axial (GemImageOrientation.XY)
    end
    
end

