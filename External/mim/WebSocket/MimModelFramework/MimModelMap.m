classdef MimModelMap < CoreBaseClass

    properties (Access = private)
        ModelCache
    end
    
    methods
        function obj = MimModelMap()
            obj.ModelCache = containers.Map();
        end
        
        function value = getValue(obj, modelId)
            model = obj.ModelCache(modelId);
            value = model.getOrRun();
        end
        
        function value = getDependentValue(obj, modelId, dependentModel)
            % Gets a model value and adds the caller as a dependent
            
            model = obj.ModelCache(modelId);
            model.addDependentModel(dependentModel);
            value = model.getOrRun();
        end        
        
        function setValue(obj, modelId, value)
            model = obj.ModelCache(modelId);
            model.setValue(value);
        end
        
        function autoUpdate(obj)
            % Triggers updating of invalid models that have AutoUpdate

            for model = obj.ModelCache.values()
                model{1}.update();
            end
        end
        
        function modelId = buildModelId(obj, modelClassName, parameters)
            % ToDo: Check parameters so as not to duplicate identical models
            
            modelConstructor = str2func(modelClassName);
            modelId = CoreSystemUtilities.GenerateUid();
            obj.ModelCache(modelId) = modelConstructor(modelId, parameters, obj, true);
        end
    end
end

