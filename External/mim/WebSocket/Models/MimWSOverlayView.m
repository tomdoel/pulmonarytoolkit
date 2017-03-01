classdef MimWSOverlayView < MimWSModel
    properties
        InstanceList
        Dataset
        Image
        Hash
        SeriesUid
        AxialDimension
    end

    methods
        function obj = MimWSOverlayView(mim, modelUid, parameters)
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
                segs = obj.Dataset.GetListOfManualSegmentations;
                if any(strcmp(segs, 'SlicSeg'))
                    obj.Image = obj.Dataset.LoadManualSegmentation('SlicSeg');
                else
                    obj.Image = obj.Dataset.GetTemplateImage(PTKContext.OriginalImage);
                    obj.Image.ImageType = PTKImageType.Colormap;
                    rawImage = zeros(obj.Image.ImageSize, 'uint8');
                    ball = CoreImageUtilities.CreateBallStructuralElement([1,1,1], 100);
                    imageSize = obj.Image.ImageSize;
                    ballSize = size(ball);
                    minSize = min(imageSize, ballSize);
                    ball = ball(1:minSize(1), 1:minSize(2), 1:minSize(3));
                    rawImage(1:size(ball,1), 1:size(ball,2), 1:size(ball,3)) = ball;
                    obj.Image.ChangeRawImage(rawImage);
                    obj.Dataset.SaveManualSegmentation('SlicSeg', obj.Image);
                end
                
                [~, obj.AxialDimension] = max(obj.Image.VoxelSize);
                
                for axial_index = 1 : obj.Image.ImageSize(obj.AxialDimension)
                    newInstanceUid = CoreSystemUtilities.GenerateUid();
                    parameters = {};
                    parameters.imageHandle = obj.Image;
                    parameters.imageSliceNumber = axial_index;
                    parameters.parentView = obj.ModelUid;
                    parameters.axialDimension = obj.AxialDimension;
                    parameters.imageType = 2;
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
            key = [parameters.seriesUid '-SS'];
        end
    end    
end