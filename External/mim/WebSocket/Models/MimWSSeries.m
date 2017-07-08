classdef MimWSSeries < MimModel
    properties
        BackgroundViewModelId
        SegmentationViewModelId
        EditViewModelId
    end
        
    methods
        function obj = MimWSSeries(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
            
            datasetModelId = obj.buildModelId('MimWSDataset', struct('seriesUid', parameters.seriesUid));
            imageVolumeId = obj.buildModelId('MimImageVolume', struct('datasetModelId', datasetModelId));
            segmentationVolumeId = obj.buildModelId('MimSegmentationVolume', struct('datasetModelId', datasetModelId, 'segmentationName', 'BRAIN'));
            
            parameters = {};
            parameters.imageVolumeId = imageVolumeId;
            parameters.segmentationVolumeId = segmentationVolumeId;
            parameters.seriesUid = obj.SeriesUid;
            parameters.seriesModelId = obj.ModelId;
            parameters.datasetId = datasetModelId;

            obj.BackgroundViewModelId = obj.buildModelId('MimWSDataView', struct('imageVolumeId', imageVolumeId));
            obj.SegmentationViewModelId = obj.buildModelId('MimWSOverlayView', parameters);
            obj.EditViewModelId = obj.buildModelId('MimWSEditView', parameters);
        end
    end
    
    methods (Access = protected)        
        function value = run(obj)
            value = {};
            value.backgroundViewModelUid = obj.BackgroundViewModelId;
            value.segmentationViewModelUid = obj.SegmentationViewModelId;
            value.editViewModelUid = obj.EditViewModelId;
        end        
    end
end