classdef MimSeries < MimModel
    properties
        SeriesUid
        BackgroundViewModelId
        SegmentationViewModelId
        EditViewModelId
%         Hash
    end
        
    methods
        function obj = MimSeries(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
            obj.SeriesUid = parameters.seriesUid;
%             obj.Hash = 0;
            
            datasetModelId = obj.buildModelId('MimWSDataset', struct('seriesUid', parameters.seriesUid));
            imageVolumeId = obj.buildModelId('MimImageVolume', struct('datasetModelId', datasetModelId));
            
            parameters = {};
            parameters.imageVolumeId = imageVolumeId;
            parameters.seriesUid = obj.SeriesUid;
            parameters.seriesModelId = obj.ModelId;

            obj.BackgroundViewModelId = obj.buildModelId('MimWSDataView', parameters);
            obj.SegmentationViewModelId = obj.buildModelId('MimWSOverlayView', parameters);
            obj.EditViewModelId = obj.buildModelId('MimWSEditView', parameters);
        end
        
        function value = run(obj)
%             obj.Hash = obj.Hash + 1;
            value = {};
            value.backgroundViewModelUid = obj.BackgroundViewModelId;
            value.segmentationViewModelUid = obj.SegmentationViewModelId;
            value.editViewModelUid = obj.EditViewModelId;
%             hash = obj.Hash;
        end        
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = parameters.seriesUid;
        end
    end    
end