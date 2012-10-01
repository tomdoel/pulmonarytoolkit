classdef TDPluginDependencyTracker < handle
    % TDPluginDependencyTracker. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     TDPluginDependencyTracker is used by TDDataset to fetch plugin results
    %     and run plugins, and build a dependency list for the plugin.
    %     A plugin may require the result of another plugin during its
    %     execution. This is a dependency, and the complete list of dependencies
    %     for a plugin must be stored (including indirect dependencies, such as
    %     when a plugin depends on a second plugin which itself depends on a
    %     third plugin).
    %
    %     Dependencies allow us to determine whether a plugin result cached on
    %     disk is still valid. A cached result s valid if all of its
    %     dependencies are valid. Every result has a unique id which is stored
    %     as part of the dependency information. If the unique id stored in the
    %     dependency list does not match the id of the current cached result,
    %     then we know the cached plugin result is invalid and the plugin must
    %     be re-run.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    properties
        % Loads and saves data associated with this dataset and ensures dependencies are valid
        DatasetDiskCache
    end
    
    methods
        
        function obj = TDPluginDependencyTracker(dataset_disk_cache)
            obj.DatasetDiskCache = dataset_disk_cache;
        end
        
        % Gets a plugin result, from the disk cache if possible. If there is no
        % cached result, or if the dependencies are invalid, or if the
        % "AlwaysRunPlugin" property is set, then the plugin is executed.
        function [result, plugin_has_been_run] = GetResult(obj, plugin_name, plugin_info, dataset_callback, dataset_call_stack, reporting)
            
            % Fetch plugin result from the disk cache
            result = [];
            if ~plugin_info.AlwaysRunPlugin
                
                [result, cache_info] = obj.DatasetDiskCache.LoadPluginResult(plugin_name, reporting);
                
                % Add the dependencies of the cached result to any other
                % plugins in the callstack
                if ~isempty(result) && ~isempty(cache_info)
                    dependencies = cache_info.DependencyList;
                    dataset_call_stack.AddDependenciesToAllPluginsInStack(dependencies);
                    
                    dependency = cache_info.InstanceIdentifier;
                    dependency_list_for_this_plugin = TDDependencyList;
                    dependency_list_for_this_plugin.AddDependency(dependency);
                    dataset_call_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_this_plugin);
                end
                
            end
            
            % Run the plugin
            if isempty(result)
                plugin_has_been_run = true;
                
                ignore_dependency_checks = plugin_info.AlwaysRunPlugin || ~plugin_info.AllowResultsToBeCached;
                
                dataset_call_stack.CreateAndPush(plugin_name, ignore_dependency_checks);
                
                % This is the actual call which runs the plugin
                result = plugin_info.RunPlugin(dataset_callback, reporting);
                
                new_cache_info = dataset_call_stack.Pop;
                if ~strcmp(plugin_name, new_cache_info.InstanceIdentifier.PluginName)
                    reporting.Error('TDPluginDependencyTracker:GetResult', 'Inconsistency in plugin call stack. To resolve this error, try deleting the cache for this dataset.');
                end
                
                % Get the newly calculated list of dependencies for this
                % plugin
                dependencies = new_cache_info.DependencyList;
                
                % Cache the plugin result
                if plugin_info.AllowResultsToBeCached && ~isempty(result)
                    obj.DatasetDiskCache.SavePluginResult(plugin_name, result, new_cache_info, reporting);
                else
                    obj.DatasetDiskCache.CachePluginInfo(plugin_name, new_cache_info, reporting);
                end
                
                dataset_call_stack.AddDependenciesToAllPluginsInStack(dependencies);
                
                dependency = new_cache_info.InstanceIdentifier;
                dependency_list_for_this_plugin = TDDependencyList;
                dependency_list_for_this_plugin.AddDependency(dependency);
                dataset_call_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_this_plugin);
            else
                plugin_has_been_run = false;
            end
        end        
    end
    
    methods (Access = private)
        
        function AddDependenciesToPlugin(obj, plugin_name, dependencies)
            if ~obj.DependencyList.isKey(plugin_name)
                obj.DependencyList(plugin_name) = containers.Map;
            end
            
            current_dependency_list = obj.DependencyList(plugin_name);
            dependencies_keys = dependencies.keys;
            for index = 1 : length(dependencies_keys)
                next_dependency = dependencies(dependencies_keys{index});
                if current_dependency_list.isKey(next_dependency.name)
                    current_dependency = current_dependency_list(next_dependency.name);
                    if ~strcmp(next_dependency.uid, current_dependency.uid)
                        error('Mismatch in dependency version uids');
                    end
                else
                    current_dependency_list(next_dependency.name) = next_dependency;
                end
            end
            obj.DependencyList(plugin_name) = current_dependency_list;
        end
    end    
end

