classdef MimWSOverlayView < MimModel
    methods
        function obj = MimWSOverlayView(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            instanceList = {};
            segmentationVolumeId = obj.Parameters.segmentationVolumeId;
            overlayImage = obj.getModelValue(obj.segmentationVolumeId);
            [~, axialDimension] = max(overlayImage.VoxelSize);
            for axial_index = 1 : overlayImage.ImageSize(axialDimension)
                parameters = {};
                parameters.imageVolumeModelId = segmentationVolumeId;
                parameters.imageSliceNumber = axial_index;
                parameters.parentViewModelId = obj.ModelId;
                parameters.axialDimension = axialDimension;
                parameters.imageType = 2;
                imageSliceModelId = obj.buildModelId('MimWSImageSlice', parameters);
                instanceList{end + 1} = struct('imageId', ['mim:' imageSliceModelId]);
            end
            value = struct('instanceList', instanceList);
        end
    end
end
