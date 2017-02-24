classdef (Abstract) MimWSModel  < handle
	
    properties (Access = protected)
        Mim
        ModelUid
        Parameters
    end
    
    properties (Access = private)
        DerivedModelMap
    end
    
    methods (Abstract)
        value = getValue(obj, modelList)
    end
    
    methods (Static)
        key = getKeyFromParameters(parameters)
    end
    
    methods
        function obj = MimWSModel(mim, modelUid, parameters)
            obj.Mim = mim;
            obj.ModelUid = modelUid;
            obj.Parameters = parameters;
            obj.DerivedModelMap = MimDerivedModelMap();
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