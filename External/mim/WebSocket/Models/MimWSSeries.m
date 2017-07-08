classdef MimWSSeries < MimModel
    methods
        function obj = MimWSSeries(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)        
        function value = run(obj)            
            datasetModelId = obj.buildModelId('MimWSDataset', struct('seriesUid', obj.Parameters.seriesUid));
            imageVolumeId = obj.buildModelId('MimImageVolume', struct('datasetModelId', datasetModelId));
            segmentationVolumeId = obj.buildModelId('MimSegmentationVolume', struct('datasetModelId', datasetModelId, 'segmentationName', 'BRAIN'));

            backgroundViewModelId = obj.buildModelId('MimWSDataView', struct('imageVolumeId', imageVolumeId));
            segmentationViewModelId = obj.buildModelId('MimWSDataView', struct('imageVolumeId', segmentationVolumeId));
            editViewModelId = obj.buildModelId('MimWSEditView', struct('segmentationVolumeId', segmentationVolumeId));
            
            value = {};
            value.backgroundViewModelUid = backgroundViewModelId;
            value.segmentationViewModelUid = segmentationViewModelId;
            value.editViewModelUid = editViewModelId;
        end        
    end
end