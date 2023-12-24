classdef MimDicomMetadata < handle
    % Returns tags for creating Dicom files
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    properties (Constant)
        DicomVersion = '0.1'
        DicomName = 'TD Medical Imaging and Modelling Toolkit'
        DicomManufacturer = 'www tomdoel com'
        DicomStudyDescription = 'TD Medical Imaging and Modelling Toolkit exported images'
    end
end

