classdef MimDicomMetadata < handle
    % MimDicomMetadata. Returns tags for creating Dicom files
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Constant)
        DicomVersion = '0.1'
        DicomName = 'TD Medical Imaging and Modelling Toolkit'
        DicomManufacturer = 'www tomdoel com'
        DicomStudyDescription = 'TD Medical Imaging and Modelling Toolkit exported images'
    end
end

