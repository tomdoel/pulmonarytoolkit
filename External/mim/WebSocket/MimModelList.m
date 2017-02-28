classdef MimModelList < CoreBaseClass
    
    properties (Access = private)
        Mim
        Models
        ModelClasses
    end
    
    methods
        function obj = MimModelList(mim)
            obj.Mim = mim;
            obj.Models = containers.Map;
            obj.ModelClasses = containers.Map;
            obj.addModel('MimSubjectList', MimSubjectList(mim, 'MimSubjectList', {}));
            
            obj.ModelClasses('MimSubject') = {@MimSubject, @MimSubject.getKeyFromParameters};
            obj.ModelClasses('MimSeries') = {@MimSeries, @MimSeries.getKeyFromParameters};
        end
        
        function model = getModel(obj, modelName)
            model = obj.Models(modelName);
        end
        
        function [value, hash] = getValue(obj, modelName)
            [value, hash] = obj.Models(modelName).getValue(obj);
        end
        
        function addModel(obj, modelName, model)
            if obj.Models.isKey(modelName)
                % Compare model instance
                if model ~= obj.Models(modelName)
                    disp('ERROR: models do not match'); %TODO
                end
            else
                obj.Models(modelName) = model;
            end
        end
        
        function key = getModelKey(obj, modelName, parameters)
            if ~obj.ModelClasses.isKey(modelName)
                error(['Model ' modelName ' not found']);
            end
            modelHandles = obj.ModelClasses(modelName);
            keyHandle = modelHandles{2};
            key = keyHandle(parameters);
        end
        
        function newObject = createNewModel(obj, modelName, modelUid, parameters)
            if ~obj.ModelClasses.isKey(modelName)
                error(['Model ' modelName ' not found']);
            end
            modelHandles = obj.ModelClasses(modelName);
            constructorHandle = modelHandles{1};
            newObject = constructorHandle(obj.Mim, modelUid, parameters);
        end
        
        function clear(obj)
            obj.Models = containers.Map;
            obj.ModelClasses = containers.Map;
            obj.addModel('MimSubjectList', MimSubjectList(obj.Mim, 'MimSubjectList', {}));
            
            obj.ModelClasses('MimSubject') = {@MimSubject, @MimSubject.getKeyFromParameters};
            obj.ModelClasses('MimSeries') = {@MimSeries, @MimSeries.getKeyFromParameters};
        end
    end
end
