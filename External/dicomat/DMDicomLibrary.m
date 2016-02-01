classdef (Sealed) DMDicomLibrary < DMDicomLibraryInterface
    % DMDICOMLIBRARY DicoMat implementation of DMDicomLibraryInterface for
    % reading Dicom data. 
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %
    
    methods
        function isDicom = isdicom(obj, fileName)
            % Tests whether a file is in DICOM format
            
            isDicom = DMisdicom(fileName);
        end
        
        function metaheader = dicominfo(obj, varargin)
            % Reads the metaheader data from a Dicom file
            
            metaheader = DMdicominfo(varargin{:});
        end
        
        function imageData = dicomread(obj, fileName_or_metaHeader)
            % Reads the image data from a Dicom file
            
            imageData = DMdicomread(fileName_or_metaHeader);
        end
        
    end
    
    methods (Access = private)
        function obj = DMDicomLibrary
        end
    end
    
    methods (Static)
        function singleObj = getLibrary
            persistent singleton
            if isempty(singleton) || ~isvalid(singleton)
                singleton = DMDicomLibrary;
            end
            singleObj = singleton;
        end
    end    
end

