classdef PTKCoordinateSystem
    % PTKCoordinateSystem. An enumeration used to specify the coordinate system used when 
    %     importing or exporting coordinates
    %
    % Different imaging programs use different coordinate systems. Therefore,
    % if you import or export image coordinates from/to another imaging program,
    % you need to tell PTK what origin to use, otherwise the coordinates will
    % not match.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    enumeration
        PTK                % Coordinates in mm relatve to the top-left corner of the image volume
        Dicom              % Coordinates in mm relative to the scanner origin
        DicomUntranslated  % Origin in the centre of the first voxel of the image
    end
    
end

