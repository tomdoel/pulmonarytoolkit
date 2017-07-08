classdef MimWSOverlayView < MimModel
    methods
        function obj = MimWSOverlayView(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            instanceList = {};
            imageVolumeModelId = obj.Parameters.segmentationVolumeId;
            imageVolume = obj.getModelValue(imageVolumeModelId);
            [~, axialDimension] = max(imageVolume.VoxelSize);
            for axial_index = 1 : imageVolume.ImageSize(axialDimension)
                parameters = struct(...
                    'imageVolumeModelId', imageVolumeModelId, ...
                    'imageSliceNumber', axial_index, ...
                    'axialDimension', axialDimension, ...
                    'imageType', imageVolume.ImageType);
                imageSliceModelId = obj.buildModelId('MimWSImageSlice', parameters);
                instanceList{end + 1} = struct('imageId', ['mim:' imageSliceModelId]);
            end
            value = struct('instanceList', instanceList);
        end
    end
end
