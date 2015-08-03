classdef (Sealed) DMDicomLibrary < handle
    % DMDICOMLIBRARY Provides an abstraction for reading Dicom data. This
    % abstraction allows you to redirect the image reading calls to
    % different sources or different Dicom libraries.
    
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

