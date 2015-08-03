classdef (Sealed) PTKDicomFallbackLibrary < handle
    % PTKDicomFallbackLibrary uses Dicomat to parse Dicom files, but falls
    % back to the Matlab image processing toobox if it fails
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
                    error('PTKDicomFallbackLibrary:MetaDataReadFail', ['Could not read metadata from the Dicom file ' fileName '. Error:' ex.message]);
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
                    error('PTKDicomFallbackLibrary:MetaDataReadFail', ['Could not read metadata from the Dicom file ' varargin{1} '. Error:' ex.message]);
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
                    error('PTKDicomFallbackLibrary:DicomReadError', ['Error while reading the Dicom file' fileName '. Error:' ex.message]);
                end
            end
        end        
    end
    
    methods (Access = private)
        function obj = PTKDicomFallbackLibrary
        end
    end
    
    methods (Static)
        function singleObj = getLibrary
            persistent singleton
            if isempty(singleton) || ~isvalid(singleton)
                singleton = PTKDicomFallbackLibrary;
            end
            singleObj = singleton;
        end
    end
end

