classdef MimWSEditView < MimModel
    properties
        InstanceList
        Dataset
        Image
        Hash
        SeriesUid
        AxialDimension
    end

    methods
        function obj = MimWSEditView(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
            obj.Dataset = parameters.dataset;
            obj.SeriesUid = parameters.seriesUid;
            obj.AxialDimension = [];
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            instanceList = {};
            if isempty(obj.Image)
                obj.Image = obj.Dataset.GetTemplateImage(PTKContext.OriginalImage);
%                     obj.Dataset.SaveManualSegmentation('Brain', obj.Image);
                
                [~, obj.AxialDimension] = max(obj.Image.VoxelSize);
                
                for axial_index = 1 : obj.Image.ImageSize(obj.AxialDimension)
                    newInstanceUid = CoreSystemUtilities.GenerateUid();
                    parameters = {};
                    parameters.imageHandle = obj.Image;
                    parameters.overlayImageHandle = obj.OverlayImage;
                    parameters.imageSliceNumber = axial_index;
                    parameters.parentView = obj.ModelUid;
                    parameters.axialDimension = obj.AxialDimension;
                    parameters.imageType = 2;
                    imageSliceModel = MimWSEditSlice(obj.Mim, newInstanceUid, parameters);
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
            key = [parameters.seriesUid '-ED'];
        end
    end    
end