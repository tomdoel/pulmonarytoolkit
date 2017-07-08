classdef MimWSEditSlice < MimModel
    methods
        function obj = MimWSEditSlice(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            value = obj.Edits;
        end
        
        function ValueHasChanged(obj, value)
            overlayImage = obj.getModelValue(obj.Parameters.segmentationVolumeId);
            imageSliceNumber = obj.Parameters.imageSliceNumber;
            axialDimension = obj.Parameters.axialDimension;
            disp('New value for seg slice:');
            disp(value);
        end
    end
end