classdef MimSegmentationList < MimModel
    methods
        function obj = MimSegmentationList(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
        
    methods (Access = protected)
        function value = run(obj)
            datasetModelId = obj.Parameters.datasetModelId;
            dataset = obj.getModelValue(datasetModelId);
            segNames = CoreContainerUtilities.GetFieldValuesFromSet(dataset.GetListOfManualSegmentations, 'Second');            
            instanceList = {};
            for segName = segNames
                segmentationVolumeId = obj.buildModelId('MimSegmentationVolume', struct('datasetModelId', datasetModelId, 'segmentationName', segName{1}));
                instanceList{end + 1} = segmentationVolumeId;
            end
            obj.CollectionItems = instanceList;
            value = obj.CollectionItems;
        end
    end
end
