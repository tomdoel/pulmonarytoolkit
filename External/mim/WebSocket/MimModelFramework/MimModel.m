classdef (Abstract) MimModel  < CoreBaseClass
	
    properties
        AutoUpdate
    end
    
    properties (SetAccess = private)
        Callback
        ModelId
        Parameters
        Valid
        Hash
    end
    
    properties (Access = protected)
        CollectionItems
    end
    
    properties (Access = private)
        Dependents
        LastValue
    end
    
    methods (Abstract, Access = protected)
        value = run(obj)
    end
    
    methods (Access = protected)
        function ValueHasChanged(obj, value)
        end
    end
    
    methods
        function obj = MimModel()
        end
        
        function initialise(obj, modelId, parameters, callback, autoUpdate)
            obj.ModelId = modelId;
            obj.Parameters = parameters;
            obj.Callback = callback;
            obj.AutoUpdate = autoUpdate;
            obj.Dependents = containers.Map();
            obj.Valid = false;
            obj.CollectionItems = {};
            obj.Hash = 0;
        end
        
        function invalidate(obj)
            % Invalidates this model and all of its dependents
            
            obj.Valid = false;
            for dependent = obj.Dependents.values()
                dependent{1}.invalidate();
            end
        end
        
        function update(obj)
            % Runs the model if it is invalid and AutoUpdate is true

            if obj.AutoUpdate
                obj.getOrRun();
            end
        end
        
        function setValue(obj, value)
            % Modifies the model value
            
            if ~obj.Valid || ~isequal(obj.LastValue, value)
                obj.invalidate();
                obj.LastValue = value;
                obj.ValueHasChanged(value);
                obj.Valid = true;
            end
        end
        
        function addDependentModel(obj, model)
            modelId = model.ModelId;
            if ~obj.Dependents.isKey(modelId)
                obj.Dependents(modelId) = model;
            end
        end
        
        function addItem(obj, itemId)
            if ~ismember(itemId, obj.CollectionItems)
                obj.CollectionItems{end + 1} = itemId;
                obj.setValue(obj.CollectionItems);
            end
        end
        
        function removeItem(obj, itemId)
            if ismember(itemId, obj.CollectionItems)
                obj.CollectionItems = setdiff(obj.CollectionItems, itemId);
                obj.setValue(obj.CollectionItems);
            end
        end
        
        function [value, hash] = getOrRun(obj)
            % Fetches the model result, running it if it is invalid
            
            if ~obj.Valid
                obj.LastValue = obj.run();
                obj.Hash = obj.Hash + 1;
                obj.Valid = true;
            end
            
            value = obj.LastValue;
            hash = obj.Hash;
        end
    end
end
