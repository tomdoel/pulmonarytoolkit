classdef MimWSEditView < MimModel
    methods
        function obj = MimWSEditView(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            instanceList = {};
            segmentationVolumeId = obj.Parameters.segmentationVolumeId;
            overlayImage = obj.getModelValue(segmentationVolumeId);
            [~, axialDimension] = max(overlayImage.VoxelSize);
                
            for axialIndex = 1 : overlayImage.ImageSize(axialDimension)                
                parameters = {};
                parameters.segmentationVolumeId = segmentationVolumeId;
                parameters.imageSliceNumber = axialIndex;
                parameters.axialDimension = axialDimension;
                imageSliceModelId = obj.buildModelId('MimWSEditSlice', parameters);
                
                instanceList{end + 1} = struct('imageId', ['mim:' imageSliceModelId]);
            end
            
            value = struct('instanceList', {instanceList});
        end
    end
end