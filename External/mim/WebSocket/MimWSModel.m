classdef (Abstract) MimWSModel  < CoreBaseClass
	
    properties (Access = protected)
        GeneratorCallback
        Mim
        ModelId
        Parameters
    end
    
    methods (Abstract)
        value = getValue(obj, modelList)
    end
    
    methods (Static)
        key = getKeyFromParameters(parameters)
    end
    
    methods
        function obj = MimWSModel(generatorCallback, mim, modelId, parameters)
            obj.GeneratorCallback = generatorCallback;
            obj.Mim = mim;
            obj.ModelId = modelId;
            obj.Parameters = parameters;
        end
        
        function value = getModelValue(obj, modelId)
            
        end
        
        function parameters = getParameters(obj)
            parameters = obj.Parameters;
        end
        
        function modelId = buildModelId(obj, modelClassName, parameters)
            modelId = obj.GeneratorCallback.buildModelId(modelClassName, parameters);
        end
        
        function createModel(obj, modelClassName, parameters)
            modelId = obj.buildModelId(modelClassName, parameters);
            generatorCallback.createNewModel(modelClassName, modelId, parameters);
        end
            
        function [model, modelUid] = getDerivedModel(obj, modelUid, modelName, parameters, modelList)
            modelMap = obj.DerivedModelMap.getModelMap(modelName);
            key = modelList.getModelKey(modelName, parameters);
            
            if modelMap.isKey(key)
                % Get existing model from the map. Use the provided
                % modelUid if it exists; otherwise get the uid from the
                % model itself
                model = modelMap(key);
                if isempty(modelUid)
                    modelUid = model.ModelUid;
                end

            else
                % Create a new model. Use the provided modelUid if it
                % exists; otherwise create a new uid
                if isempty(modelUid)
                    modelUid = CoreSystemUtilities.GenerateUid();
                end
                
                model  = modelList.createNewModel(modelName, modelUid, parameters);
                modelMap(key) = model;
            end

            % Add model to list using the provided alias, or verify it
            % matches the existing model in the list for that alias.
            % This will deliberately add more than one reference to the
            % same model if the same model has been created using different
            % uids
            modelList.addModel(modelUid, model);
        end        
    end
end