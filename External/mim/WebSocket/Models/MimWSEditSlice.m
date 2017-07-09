classdef MimWSEditSlice < MimModel
    methods
        function obj = MimWSEditSlice(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            value = struct();
        end
        
        function ValueHasChanged(obj, value)
            overlayImage = obj.getModelValue(obj.Parameters.segmentationVolumeId);
            imageSliceNumber = obj.Parameters.imageSliceNumber;
            axialDimension = obj.Parameters.axialDimension;
            disp('New value for seg slice:');
            disp(value);
            
            slice = overlayImage.GetSlice(imageSliceNumber, axialDimension);
            strokesArray = value.data;
            
            for stroke = strokesArray
                colour = MimWSEditSlice.stringToColour(stroke{1}.colour);
                pointsArray = stroke{1}.points;
                for point = pointsArray
                    x = point{1}.x;
                    y = point{1}.y;
                    slice(max(1, round(x)), max(1, round(y))) = colour;
                end
            end
            
            overlayImage.ReplaceImageSlice(slice, imageSliceNumber, axialDimension);
            obj.setModelValue(obj.Parameters.segmentationVolumeId, overlayImage.Copy());
        end
    end
    
    methods (Static, Access = private)
        function colourIndex = stringToColour(colourString)
            switch(colourString)
                case 'blue'
                    colourIndex = 1;
                case 'green'
                    colourIndex = 2;
                case 'red'
                    colourIndex = 3;
                case 'cyan'
                    colourIndex = 4;
                case 'magenta'
                    colourIndex = 5;
                case 'yellow'
                    colourIndex = 6;
                case 'grey'
                    colourIndex = 7;
                otherwise
                    colourIndex = 1;
            end
        end
    end
end