classdef MimWSImageSlice < MimModel
    methods
        function obj = MimWSImageSlice(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            imageType = obj.Parameters.imageType;
            imageVolume = obj.getModelValue(obj.Parameters.imageVolumeModelId);
            slice = imageVolume.GetSlice(obj.Parameters.imageSliceNumber, obj.Parameters.axialDimension);
            globalMin = imageVolume.Limits(1);
            globalMax = imageVolume.Limits(2);
            if imageType == 2
                slice = uint8(slice);
            else
                if isfloat(slice)
                    % TODO: Rescale to max 254 to address client rendering issues
                    slice = uint16(254*(slice - globalMin)/(globalMax - globalMin));
%                     value = uint16(65535*(value - globalMin)/(globalMax - globalMin));
                end
            end
            value = MimImageStorage(slice, imageType);
        end
    end
end
