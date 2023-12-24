classdef DMDicomLibraryInterface < CoreBaseClass
    % Interface for a class that parses Dicom files
    %
    % This interface allows you to use your own Dicom parsing libraries
    % with DicoMat functions, by wrapping them up in a class that
    % implements this interface.
    %
    %
    % .. Licence
    %    -------
    %    Part of DicoMat. https://github.com/tomdoel/dicomat
    %    Author: Tom Doel, 2015.  www.tomdoel.com
    %    Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %
    
    methods (Abstract)
        
        % Tests whether a file is in DICOM format
        isDicom = isdicom(obj, fileName)
        
        % Reads the metaheader data from a Dicom file
        metaheader = dicominfo(obj, varargin)
        
        % Reads the image data from a Dicom file
        imageData = dicomread(obj, fileName_or_metaHeader)
        
    end
end

