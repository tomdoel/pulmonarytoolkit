classdef PTKCoordinateSystem
    % PTKCoordinateSystem. Legacy support class for backwards compatibility. Replaced by MimCoordinateSystem
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (Constant)
        PTK = MimCoordinateSystem.PTK;                 % Coordinates in mm relatve to the top-left corner of the image volume
        Dicom = MimCoordinateSystem.Dicom              % Coordinates in mm relative to the scanner origin
        DicomUntranslated = MimCoordinateSystem.DicomUntranslated  % Origin in the centre of the first voxel of the image
    end
end

