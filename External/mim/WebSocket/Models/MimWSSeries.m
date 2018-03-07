classdef MimWSSeries < MimModel
    methods (Access = protected)        
        function value = run(obj)            
            datasetModelId = obj.Callback.buildModelId('MimWSDataset', struct('seriesUid', obj.Parameters.seriesUid));
            imageVolumeId = obj.Callback.buildModelId('MimImageVolume', struct('datasetModelId', datasetModelId));
            segmentationListId = obj.Callback.buildModelId('MimSegmentationList', struct('datasetModelId', datasetModelId));
            segmentationIds = obj.Callback.getModelValue(segmentationListId);
            firstSegmentation = segmentationIds{1};
            
            backgroundViewModelId = obj.Callback.buildModelId('MimWSDataView', struct('imageVolumeId', imageVolumeId));
            segmentationViewModelId = obj.Callback.buildModelId('MimWSDataView', struct('imageVolumeId', firstSegmentation));
            editViewModelId = obj.Callback.buildModelId('MimWSEditView', struct('segmentationVolumeId', firstSegmentation));
            
            value = {};
            value.backgroundViewModelId = backgroundViewModelId;
            value.segmentationViewModelId = segmentationViewModelId;
            value.editViewModelId = editViewModelId;
        end        
    end
end