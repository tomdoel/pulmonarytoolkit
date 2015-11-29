classdef PTKImageOrientation < uint8
    % PTKImageOrientation. An enumeration used to specify the orientation of an
    % image
    %
    %     The number values correspond to the dimension axis perpendicular to
    %     the view
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    enumeration
        Coronal (GemImageOrientation.XZ)
        Sagittal (GemImageOrientation.YZ)
        Axial (GemImageOrientation.XY)
    end
    
end

