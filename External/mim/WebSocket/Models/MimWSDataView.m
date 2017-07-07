classdef MimWSDataView < MimModel
    properties
        InstanceList
        Dataset
        Image
        SeriesUid
        AxialDimension
    end

    methods
        function obj = MimWSDataView(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
            obj.Dataset = parameters.dataset;
            obj.SeriesUid = parameters.seriesUid;
            obj.ImageVolumeModelId = parameters.imageVolumeId;
            obj.AxialDimension = [];
        end
        
        function value = run(obj)
            obj.Hash = obj.Hash + 1;
            instanceList = {};
            if isempty(obj.Image)
                obj.Image = obj.getValue(obj.ImageVolumeModelId);
                [~, obj.AxialDimension] = max(obj.Image.VoxelSize);
                for axial_index = 1 : obj.Image.ImageSize(obj.AxialDimension)
                    newInstanceUid = CoreSystemUtilities.GenerateUid();
                    parameters = {};
                    parameters.imageVolumeModelId = obj.ImageVolumeModelId;
                    parameters.imageSliceNumber = axial_index;
                    parameters.parentViewModelId = obj.ModelId;
                    parameters.axialDimension = obj.AxialDimension;
                    parameters.imageType = 1;
                    imageSliceModelId = obj.buildModelId('MimWSImageSlice', parameters);
%                     imageSliceModel = MimWSImageSlice(obj.Mim, newInstanceUid, parameters);
%                     modelList.addModel(newInstanceUid, imageSliceModel);
                    instanceStruct = {};
                    instanceStruct.imageId = ['mim:' imageSliceModelId];
                    instanceList{end + 1} = instanceStruct;
                end
                obj.InstanceList = instanceList;
            end
            value = {};
            value.instanceList = obj.InstanceList;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = [parameters.seriesUid '-DV'];
        end
    end    
    
    methods (Static, Access = private)
        function seriesListEntry = SeriesListEntry(modelUid, seriesDescription, modality)
            persistent seriesNumber
            if isempty(seriesNumber)
                seriesNumber = 1;
            end
            seriesListEntry = struct();
            seriesListEntry.modelUid = modelUid;
            seriesListEntry.seriesDescription = seriesDescription;
            seriesListEntry.modality = modality;
            seriesListEntry.seriesNumber = seriesNumber;
            seriesNumber = seriesNumber + 1;
        end        
    end
end