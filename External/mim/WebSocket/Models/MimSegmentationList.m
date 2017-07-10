classdef MimSegmentationList < MimModel
    methods (Access = protected)
        function value = run(obj)
            datasetModelId = obj.Parameters.datasetModelId;
            dataset = obj.Callback.getModelValue(datasetModelId);
            segNames = CoreContainerUtilities.GetFieldValuesFromSet(dataset.GetListOfManualSegmentations, 'Second');            
            instanceList = {};
            for segName = segNames
                segmentationVolumeId = obj.Callback.buildModelId('MimSegmentationVolume', struct('datasetModelId', datasetModelId, 'segmentationName', segName{1}));
                instanceList{end + 1} = segmentationVolumeId;
            end
            obj.CollectionItems = instanceList;
            value = obj.CollectionItems;
        end
    end
end
