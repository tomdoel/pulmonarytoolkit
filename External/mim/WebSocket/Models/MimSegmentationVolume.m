classdef MimSegmentationVolume < MimModel
    methods
        function obj = MimSegmentationVolume(modelId, parameters, modelMap, autoUpdat)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdat);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            datasetModelId = obj.Parameters.datasetModelId;
            segmentationName = obj.Parameters.segmentationName;            
            dataset = obj.getModelValue(datasetModelId);
            segs = CoreContainerUtilities.GetFieldValuesFromSet(dataset.GetListOfManualSegmentations, 'Second');
            if any(strcmp(segs, segmentationName))
                segImage = dataset.LoadManualSegmentation(segmentationName);
            else
                segImage = dataset.GetTemplateImage(PTKContext.OriginalImage);
                segImage.ImageType = PTKImageType.Colormap;
                rawImage = zeros(segImage.ImageSize, 'uint8');
                ball = CoreImageUtilities.CreateBallStructuralElement([1,1,1], 100);
                imageSize = segImage.ImageSize;
                ballSize = size(ball);
                minSize = min(imageSize, ballSize);
                ball = ball(1:minSize(1), 1:minSize(2), 1:minSize(3));
                rawImage(1:size(ball,1), 1:size(ball,2), 1:size(ball,3)) = ball;
                segImage.ChangeRawImage(rawImage);
                dataset.SaveManualSegmentation(segmentationName, segImage);
            end
            value = segImage;
        end
    end
end