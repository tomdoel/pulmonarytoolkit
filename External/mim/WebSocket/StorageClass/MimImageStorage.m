classdef MimImageStorage < MimStorageClass
    
    properties
        RawImage
        ImageType
    end
    
    methods
        function obj = MimImageStorage(rawImage, imageType)
            obj.RawImage = rawImage;
            obj.ImageType = imageType;
        end
        
        function [metaData, dataStream] = getStream(obj)
            dataStream = typecast(obj.RawImage(:), 'int8');
            metaData = struct('dataType', class(obj.RawImage), 'dataDims', size(obj.RawImage), 'imageType', obj.ImageType);
        end
    end
    
end

