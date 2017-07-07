classdef MimWSEditSlice < MimWSModel
    properties
        Image
        AxialDimension
        ImageSliceNumber
        Hash
        ParentView
        Edits
    end

    methods
        function obj = MimWSEditSlice(generatorCallback, mim, modelUid, parameters)
            obj = obj@MimWSModel(generatorCallback, mim, modelUid, parameters);
            obj.Image = parameters.imageHandle;
            obj.OverlayImage = parameters.overlayImageHandle;

            obj.ImageSliceNumber = parameters.imageSliceNumber;
            obj.AxialDimension = parameters.axialDimension;
            obj.ParentView = parameters.parentView;
            obj.Hash = 0;
            obj.Edits = struct;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            value = obj.Edits;
            hash = obj.Hash;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = [parameters.parentView '-' num2str(parameters.imageSliceNumber)];
        end
    end    
end