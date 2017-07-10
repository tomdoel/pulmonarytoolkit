classdef MimModelCallback  < CoreBaseClass
	
    properties (Access = private)
        ModelId
        ModelMap
        Mim
    end
    
    methods
        function obj = MimModelCallback(modelId, modelMap, mim)
            obj.ModelId = modelId;
            obj.ModelMap = modelMap;
            obj.Mim = mim;
        end
        
        function value = getModelValue(obj, modelId)
            % Returns the current value of the specified model
            
           value = obj.ModelMap.getDependentValue(modelId, obj.ModelId);
        end
        
        function setModelValue(obj, modelId, value)
            % Sets the current value of the specified model
            
           obj.ModelMap.setValue(modelId, value);
        end

        function addModelItem(obj, modelId, itemId)
           obj.ModelMap.addItem(modelId, itemId);
        end
        
        function removeModelItem(obj, modelId, itemId)
           obj.ModelMap.removeItem(modelId, itemId);
        end
        
        function modelId = buildModelId(obj, modelClassName, parameters)
            modelId = obj.ModelMap.buildModelId(modelClassName, parameters);
        end
                
        function mim = getMim(obj)
            mim = obj.Mim;
        end
    end
end
