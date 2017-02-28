classdef MimWSOverlayView < MimWSModel
    properties
        InstanceList
        Dataset
        Image
        Hash
        SeriesUid
    end

    methods
        function obj = MimWSOverlayView(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);
            obj.Dataset = parameters.dataset;
            obj.SeriesUid = parameters.seriesUid;
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            instanceList = {};
            if isempty(obj.Image)
                segs = obj.Dataset.GetListOfManualSegmentations;
                if any(strcmp(segs, 'SlicSeg'))
                    obj.Image = obj.Dataset.LoadManualSegmentation('SlicSeg');
                else
                    obj.Image = obj.Dataset.GetTemplateImage('PTKOriginalImage');
                    obj.Image.ImageType = PTKImageType.Colormap;
                    obj.Image.ChangeRawImage(zeros(newImage.ImageSize, 'uint8'));
                    obj.Dataset.SaveManualSegmentation('SlicSeg', obj.Image);
                end
                
                for axial_index = 1 : obj.Image.ImageSize(3);
                    obj.InstanceUids(axial_index) = CoreSystemUtilities.GenerateUid();
                    parameters = {};
                    parameters.imageHandle = obj.Image;
                    parameters.imageSliceNumber = axial_index;
                    parameters.parentView = obj.ModelUid;
                    imageSliceModel = MimWSImageSlice(obj.Mim, obj.InstanceUids(axial_index), parameters);
                    modelList.addModel(obj.Mim, obj.InstanceUids(axial_index), imageSliceModel);
                    instanceList{end + 1} = obj.InstanceUids(axial_index);
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
end