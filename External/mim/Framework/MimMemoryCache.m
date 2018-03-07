classdef MimMemoryCache < handle
    % MimMemoryCache. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     Used to cache plugin results in memory.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        
    
    properties (Access = private)
        MemoryCacheMap
        TemporaryKeys % Keys that will be cleared by ClearTemporaryResults()
    end
    
    methods
        
        function obj = MimMemoryCache(reporting)
            obj.Delete(reporting);
        end
        
        function exists = Exists(obj, name, context, ~)
            exists = obj.MemoryCacheMap.isKey(MimMemoryCache.GetKey(name, context));
        end

        function [result, info] = Load(obj, name, context, reporting)
            % Load a result from the cache
            
            if obj.Exists(name, context, reporting)
                cache_item = obj.MemoryCacheMap(MimMemoryCache.GetKey(name, context));
                result = cache_item.Value;
                if isa(result, 'handle')
                    if isa(result, 'PTKImage')
                        result = result.Copy();
                    else
                        error('Handle type in memory cache!');
                    end
                end
                if (nargout > 1)
                    info = cache_item.Info;
                end
            else
                result = []; 
                info = [];
             end
        end
        
        function Save(obj, name, value, context, cache_policy, reporting)
            % Save a result to the cache

            obj.Add(name, value, [], context, cache_policy, reporting);
        end

        function SaveWithInfo(obj, name, value, info, context, cache_policy, reporting)
            % Save a result to the cache

            obj.Add(name, value, info, context, cache_policy, reporting);
        end
        
        function Delete(obj, ~)
            % Clears the cache
            
            obj.MemoryCacheMap = containers.Map;
            obj.TemporaryKeys = [];
        end

        function DeleteCacheFile(obj, name, context, reporting)
            key = MimMemoryCache.GetKey(name, context);
            if obj.MemoryCacheMap.isKey(key)
                obj.MemoryCacheMap.remove(key);
            end
            if any(ismember(obj.TemporaryKeys, key))
                obj.TemporaryKeys(ismember(obj.TemporaryKeys, keys)) = [];
            end
        end

        function RemoveAllCachedFiles(obj, ~, reporting)
            % Clears the cache
            
            obj.Delete(reporting);
        end
        
        function ClearTemporaryResults(obj)
            for key = obj.TemporaryKeys
                if obj.MemoryCacheMap.isKey(key{1})
                    obj.MemoryCacheMap.remove(key{1});
                end
            end
            obj.TemporaryKeys = [];
        end
    end
    
    methods (Access = private)
        function Add(obj, name, value, info, context, cache_policy, reporting)
            switch cache_policy
                case MimCachePolicy.Off
                    cache = false;
                    is_temporary = false;
                case MimCachePolicy.Temporary
                    cache = true;
                    is_temporary = true;
                case MimCachePolicy.Session
                    cache = true;
                    is_temporary = false;
                case MimCachePolicy.Permanent
                    cache = true;
                    is_temporary = false;
                otherwise
                    reporting.Error('MimMemoryCache:UnknownCachePolicy', 'The memory cache policy was not recognised.');
            end
            
            % We do not generally save handle types since they could be altered from
            % outside. But we can deep copy PTKImage types.
            if cache && isa(value, 'handle')
                if isa(value, 'PTKImage')
                    value = value.Copy();
                else
                    cache = false;
                end
            end
            
            if cache            
                new_key = MimMemoryCache.GetKey(name, context);
                obj.MemoryCacheMap(new_key) = MimMemoryCacheItem(value, info);
                if is_temporary
                    obj.TemporaryKeys{end + 1} = new_key;
                    obj.TemporaryKeys = unique(obj.TemporaryKeys);
                end
            end
        end        
    end
        
    methods (Static, Access = private)
        function key_name = GetKey(name, context)
            key_name = [char(name) '.' char(context)];
        end
    end
end
