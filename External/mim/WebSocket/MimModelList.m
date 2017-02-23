classdef MimModelList < CoreBaseClass
    
    properties (Access = private)
        Models
    end
    
    methods
        function obj = MimModelList(mim)
            obj.Models = containers.Map;
            obj.Models('MimSubjectList') = MimSubjectList(mim);
        end
        
        function [value, hash] = getValue(obj, modelName)
            [value, hash] = obj.Models(modelName).getValue();
        end
    end
end
