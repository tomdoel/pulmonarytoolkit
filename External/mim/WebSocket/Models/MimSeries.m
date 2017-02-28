classdef MimSeries < MimWSModel
    properties
        Dataset
        SeriesUid
        BackgroundViewModelUid
        SegmentationViewModelUid
        Hash
    end
        
    methods
        function obj = MimSeries(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);            
            obj.SeriesUid = parameters.seriesUid;
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            if isempty(obj.Dataset)
                obj.getDataset(modelList);
            end
            value = {};
            value.backgroundViewModelUid = obj.BackgroundViewModelUid;
            value.segmentationViewModelUid = obj.SegmentationViewModelUid;
            hash = obj.Hash;
        end
        
        function getDataset(obj, modelList)
            obj.Dataset = obj.Mim.CreateDatasetFromUid(obj.SeriesUid);
            parameters = {};
            parameters.dataset = obj.Dataset;
            parameters.seriesUid = obj.SeriesUid;

            obj.BackgroundViewModelUid = CoreSystemUtilities.GenerateUid();
            backgroundViewModel = MimWSDataView(obj.Mim, obj.BackgroundViewModelUid, parameters);
            modelList.addModel(obj.BackgroundViewModelUid, backgroundViewModel);
            
            obj.SegmentationViewModelUid = CoreSystemUtilities.GenerateUid();
            segmentationViewModel = MimWSOverlayView(obj.Mim, obj.SegmentationViewModelUid, parameters);
            modelList.addModel(obj.SegmentationViewModelUid, segmentationViewModel);
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = parameters.seriesUid;
        end
    end    
end