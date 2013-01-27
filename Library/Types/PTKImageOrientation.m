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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    enumeration
        Coronal (1)
        Sagittal (2)
        Axial (3)
    end
    
end

