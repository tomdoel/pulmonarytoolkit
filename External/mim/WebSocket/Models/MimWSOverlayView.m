classdef MimWSOverlayView < MimModel
    properties
        InstanceList
        Dataset
        Image
        SeriesUid
        AxialDimension
    end

    methods
        function obj = MimWSOverlayView(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
            obj.Dataset = parameters.dataset;
            obj.SeriesUid = parameters.seriesUid;
            obj.AxialDimension = [];
        end
        
        function value = run(obj)
            instanceList = {};
            if isempty(obj.Image)
                segs = CoreContainerUtilities.GetFieldValuesFromSet(obj.Dataset.GetListOfManualSegmentations, 'Second');
                if any(strcmp(segs, 'Brain'))
                    obj.Image = obj.Dataset.LoadManualSegmentation('Brain');
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
                    obj.Dataset.SaveManualSegmentation('Brain', obj.Image);
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
                obj.AddEventListener(obj.Image, 'ImageChanged', @obj.ImageChangedCallback);
            end
            
            value = {};
            value.instanceList = obj.InstanceList;
        end
        
        function ImageChangedCallback(obj, ~, ~)
           obj.Hash = obj.Hash + 1; 
        end
        
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = [parameters.seriesUid '-SS'];
        end
    end    
end