classdef MimModelMap < CoreBaseClass

    properties (Access = private)
        Mim
        ModelCache
    end
    
    methods
        function obj = MimModelMap(mim)
            obj.Mim = mim;
            obj.clear();
        end
        
        function [value, hash] = getValue(obj, modelId)
            model = obj.ModelCache(modelId);    
            [value, hash] = model.getOrRun();
        end
        
        function value = getDependentValue(obj, modelId, dependentModelId)
            % Gets a model value and adds the caller as a dependent
            
            model = obj.ModelCache(modelId);
            model.addDependentModel(obj.ModelCache(dependentModelId));
            value = model.getOrRun();
        end        
        
        function setValue(obj, modelId, value)
            model = obj.ModelCache(modelId);
            model.setValue(value);
        end

        function addItem(obj, modelId, itemId)
            model = obj.ModelCache(modelId);
            model.addItem(modelId, itemId);
        end
        
        function removeItem(obj, modelId, itemId)
            model = obj.ModelCache(modelId);
            model.removeItem(itemId);
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
            model = modelConstructor();
            model.initialise(modelId, parameters, MimModelCallback(modelId, obj, obj.Mim), true);
            obj.ModelCache(modelId) = model;
        end
        
        function clear(obj)
            obj.ModelCache = containers.Map();
            % Explicitly add in models with unique names
            model = MimSubjectList();
            model.initialise('MimSubjectList', {}, MimModelCallback('MimSubjectList', obj, obj.Mim), true);
            obj.ModelCache('MimSubjectList') = model;
        end
    end
end

