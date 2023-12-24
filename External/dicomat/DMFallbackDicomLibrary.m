classdef (Sealed) DMFallbackDicomLibrary < DMDicomLibraryInterface
    % DMFallbackDicomLibrary uses Dicomat to parse Dicom files, but falls
    % back to the Matlab image processing toobox if it fails
    %
    % .. Licence
    %    -------
    %    Part of DicoMat. https://github.com/tomdoel/dicomat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %
        
    methods
        function isDicom = isdicom(~, fileName)
            % Tests whether a file is in DICOM format
            
            try
                isDicom = DMisdicom(fileName);
            catch ex
                try
                    isDicom = isdicom(fileName);
                catch ex
                    error('DMFallbackDicomLibrary:MetaDataReadFail', ['Could not read metadata from the Dicom file ' fileName '. Error:' ex.message]);
                end
            end            
        end
        
        function metaheader = dicominfo(~, varargin)
            % Reads the metaheader data from a Dicom file
            
            try
                metaheader = DMdicominfo(varargin{:});
            catch ex
                try
                    metaheader = dicominfo(varargin{1});
                catch ex
                    error('DMFallbackDicomLibrary:MetaDataReadFail', ['Could not read metadata from the Dicom file ' varargin{1} '. Error:' ex.message]);
                end
            end
        end
        
        function imageData = dicomread(~, fileName_or_metaHeader)
            % Reads the image data from a Dicom file
            
            try
                imageData = DMdicomread(fileName_or_metaHeader);
            catch ex
                try
                    imageData = dicomread(fileName_or_metaHeader);
                catch ex
                    fileName = '';
                    if isstruct(fileName_or_metaHeader) && isfield(fileName_or_metaHeader, 'Filename')
                            fileName = fileName_or_metaHeader.Filename;
                    elseif ischar(fileName_or_metaHeader)
                        fileName = fileName_or_metaHeader;
                    end
                    error('DMFallbackDicomLibrary:DicomReadError', ['Error while reading the Dicom file' fileName '. Error:' ex.message]);
                end
            end
        end        
    end
    
    methods (Access = private)
        function obj = DMFallbackDicomLibrary
        end
    end
    
    methods (Static)
        function singleObj = getLibrary
            persistent singleton
            if isempty(singleton) || ~isvalid(singleton)
                singleton = DMFallbackDicomLibrary;
            end
            singleObj = singleton;
        end
    end
end

