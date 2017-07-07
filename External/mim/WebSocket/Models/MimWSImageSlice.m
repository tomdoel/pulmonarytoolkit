classdef MimWSImageSlice < MimWSModel
    properties
        Image
        AxialDimension
        ImageSliceNumber
        Hash
        ParentView
        ImageType
    end

    methods
        function obj = MimWSImageSlice(generatorCallback, mim, modelUid, parameters)
            obj = obj@MimWSModel(generatorCallback, mim, modelUid, parameters);
            obj.Image = parameters.imageHandle;

            obj.ImageType = parameters.imageType;
            obj.ImageSliceNumber = parameters.imageSliceNumber;
            obj.AxialDimension = parameters.axialDimension;
            obj.ParentView = parameters.parentView;
            obj.Hash = 0;
            obj.AddEventListener(obj.Image, 'ImageChanged', @obj.ImageChangedCallback);
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            value = obj.Image.GetSlice(obj.ImageSliceNumber, obj.AxialDimension);
            globalMin = obj.Image.Limits(1);
            globalMax = obj.Image.Limits(2);
            if obj.ImageType == 2
                value = uint8(value);
            else
                if isfloat(value)
                    % TODO: Rescale to max 254 to address client rendering issues
                    value = uint16(254*(value - globalMin)/(globalMax - globalMin));
%                     value = uint16(65535*(value - globalMin)/(globalMax - globalMin));
                end
            end
            value = MimImageStorage(value, obj.ImageType);
            hash = obj.Hash;
        end
        
        function ImageChangedCallback(obj, ~, ~)
           obj.Hash = obj.Hash + 1; 
        end
        
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = [parameters.parentView '-' num2str(parameters.imageSliceNumber)];
        end
    end    
end