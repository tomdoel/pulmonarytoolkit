classdef MimWSDataView < MimModel
    methods
        function obj = MimWSDataView(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)        
        function value = run(obj)
            instanceList = {};
            imageVolumeModelId = obj.Parameters.imageVolumeId;
            baseImage = obj.getModelValue(imageVolumeModelId);
            [~, axialDimension] = max(baseImage.VoxelSize);
            for axial_index = 1 : baseImage.ImageSize(axialDimension)
                parameters = {};
                parameters.imageVolumeModelId = imageVolumeModelId;
                parameters.imageSliceNumber = axial_index;
                parameters.parentViewModelId = obj.ModelId;
                parameters.axialDimension = axialDimension;
                parameters.imageType = 1;
                imageSliceModelId = obj.buildModelId('MimWSImageSlice', parameters);
                instanceList{end + 1} = struct('imageId', ['mim:' imageSliceModelId]);
            end
            value = struct('instanceList', instanceList);
        end
    end
end
