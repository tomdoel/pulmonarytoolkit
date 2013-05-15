classdef MockPluginDependencyTracker < handle
    % MockPluginDependencyTracker. Part of the PTK test framework
    %
    % This class is used in tests in place of a PTKPluginDependencyTracker. It
    % allows expected calls to be verified, while maintaining some of the 
    % expected behaviour of a PTKPluginDependencyTracker object.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties
        MockResults
    end
    
    methods
        
        function obj = MockPluginDependencyTracker()
            obj.MockResults = containers.Map;            
        end
        
        function AddMockResult(obj, name, context, dataset_uid, result_to_add, cache_info, has_been_run)
            result = [];
            result.Result = result_to_add;
            result.CacheInfo = cache_info;
            result.HasBeenRun = has_been_run;
            obj.MockResults([name '.' char(context) '.' dataset_uid]) = result;
        end
        
        function cache_info = GetCacheInfo(obj, plugin_name)
        end
        
        function [result, plugin_has_been_run, cache_info] = GetResult(obj, plugin_name, context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, allow_results_to_be_cached, reporting)
                    
            key_name = [plugin_name '.' char(context) '.' dataset_uid];
            
            result_from_cache = obj.MockResults(key_name);
            result = result_from_cache.Result;
            cache_info = result_from_cache.CacheInfo;
            plugin_has_been_run = result_from_cache.HasBeenRun;
            
        end

        function valid = CheckDependencyValid(obj, next_dependency, reporting)
        end
    end
    
end

