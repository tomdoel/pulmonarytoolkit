classdef MimSegmentationVolume < MimModel
    methods (Access = protected)
        function value = run(obj)
            datasetModelId = obj.Parameters.datasetModelId;
            segmentationName = obj.Parameters.segmentationName;
            dataset = obj.Callback.getModelValue(datasetModelId);
            segs = CoreContainerUtilities.GetFieldValuesFromSet(dataset.GetListOfManualSegmentations, 'Second');
            if any(strcmpi(segs, segmentationName))
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
        
        function ValueHasChanged(obj, value)
            if isa(value, 'PTKImage')
                datasetModelId = obj.Parameters.datasetModelId;
                segmentationName = obj.Parameters.segmentationName;        
                dataset = obj.Callback.getModelValue(datasetModelId);
                dataset.SaveManualSegmentation(segmentationName, value);
            else
                disp('Error: wrong type of image');
            end
        end
    end
end