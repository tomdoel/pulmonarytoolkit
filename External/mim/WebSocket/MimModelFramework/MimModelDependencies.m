classdef MimModelDependencies < CoreBaseClass

    properties (Access = private)
        Dependencies
    end
    
    methods
        function obj = MimModelDependencies()
            obj.Dependencies = containers.Map();
        end
        
        function addDependency(obj, modelId, newDependencyModelId)
            if obj.Dependencies.isKey(modelId)
                dependencyList = obj.Dependencies(modelId);
            else
                dependencyList = {};
                obj.Dependencies(modelId) = dependencyList;
            end
            if ~dependencyList.isKey(newDependencyModelId)
                dependencyList{end + 1} = newDependencyModelId;
            end
        end
        
        function dependencyList = getDependencies(obj, modelId)
            if obj.Dependencies.isKey(modelId)
                dependencyList = obj.Dependencies(dependentModelId);
            else
                dependencyList = {};
            end
        end
    end
end