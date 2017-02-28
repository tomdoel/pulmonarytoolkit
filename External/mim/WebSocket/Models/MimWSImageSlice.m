classdef MimWSImageSlice < MimWSModel
    properties
        Image
        AxialDimension
        ImageSliceNumber
        Hash
        ParentView
    end

    methods
        function obj = MimWSImageSlice(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);
            obj.Image = parameters.imageHandle;
            obj.ImageSliceNumber = parameters.imageSliceNumber;
            obj.AxialDimension = parameters.axialDimension;
            obj.ParentView = parameters.parentView;
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            value = obj.Image.GetSlice(obj.ImageSliceNumber, obj.AxialDimension);
            hash = obj.Hash;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = [parameters.parentView '-' num2str(parameters.imageSliceNumber)];
        end
    end    
end