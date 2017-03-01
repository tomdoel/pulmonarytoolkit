classdef MimWSDataView < MimWSModel
    properties
        InstanceList
        Dataset
        Image
        Hash
        SeriesUid
        AxialDimension
    end

    methods
        function obj = MimWSDataView(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);
            obj.Dataset = parameters.dataset;
            obj.SeriesUid = parameters.seriesUid;
            obj.AxialDimension = [];
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            instanceList = {};
            if isempty(obj.Image)
                obj.Image = obj.Dataset.GetResult('PTKOriginalImage');
                [~, obj.AxialDimension] = max(obj.Image.VoxelSize);
                for axial_index = 1 : obj.Image.ImageSize(obj.AxialDimension);
                    newInstanceUid = CoreSystemUtilities.GenerateUid();
                    parameters = {};
                    parameters.imageHandle = obj.Image;
                    parameters.imageSliceNumber = axial_index;
                    parameters.parentView = obj.ModelUid;
                    parameters.axialDimension = obj.AxialDimension;
                    imageSliceModel = MimWSImageSlice(obj.Mim, newInstanceUid, parameters);
                    modelList.addModel(newInstanceUid, imageSliceModel);
                    instanceStruct = {};
                    instanceStruct.imageId = ['mim:' newInstanceUid];
                    instanceList{end + 1} = instanceStruct;
                end
                obj.InstanceList = instanceList;
            end
            value = {};
            value.instanceList = obj.InstanceList;
            hash = obj.Hash;
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