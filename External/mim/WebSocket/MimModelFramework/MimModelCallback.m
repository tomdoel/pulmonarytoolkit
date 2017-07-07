classdef MimModelCallback < CoreBaseClass

    properties (Access = private)
        ModelDependencies
        ModelList
        ModelGenerator
    end
    
    methods
        function obj = MimModelCallback()
            obj.ModelDependencies = MimModelDependencies();
        end
        
        function modelId = getModelId(obj, modelClassName, parameters)
            
        end

        function value = getValue(obj, modelId, newDependencyModelId)
            obj.ModelDependencies.addDependency(modelId, newDependencyModelId);
            if obj.ModelList.exists(modelId)
                [value, hash] = obj.ModelList.getValue(modelId);
            else
                [value, hash] = obj.runModelAndTriggerDependencies();
            end
        end
        
        function [value, hash] = runModelAndTriggerDependencies(obj, modelId)
            [currentValue, currentHash] = obj.ModelList.getValue(modelId);
            [value, hash] = obj.ModelGenerator.runModel(modelId);
            if ~isequal(currentHash, hash)
                obj.ModelList.setValue(modelId, value);
                dependencies = obj.ModelDependencies.getDependencies(modelId);
                for dependency = dependencies
                    obj.runModelAndTriggerDependencies(dependency{1});
                end
            end
        end

    end
end