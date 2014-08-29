classdef PTKPluginDependencyTracker < PTKBaseClass
    % PTKPluginDependencyTracker. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKPluginDependencyTracker is used by PTKDataset to fetch plugin results
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
        
        function obj = PTKPluginDependencyTracker(dataset_disk_cache)
            obj.DatasetDiskCache = dataset_disk_cache;
        end
        
        
        function cache_info = GetCacheInfo(obj, plugin_name)
            [result, cache_info] = obj.DatasetDiskCache.LoadPluginResult(plugin_name, reporting);
            if isempty(result) || isempty(cache_info)
                reporting.ShowWarning('PTKPluginDependencyTracker:NoCacheInfo', ['No cached value was found for plugin ' plugin_name '.'], []);
            end
        end
        
        % Gets a plugin result, from the disk cache if possible. If there is no
        % cached result, or if the dependencies are invalid, or if the
        % "AlwaysRunPlugin" property is set, then the plugin is executed.
        function [result, plugin_has_been_run, cache_info] = GetResult(obj, plugin_name, context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, allow_results_to_be_cached, reporting)
            % Fetch plugin result from the disk cache
            result = [];
            if ~plugin_info.AlwaysRunPlugin
                
                [result, cache_info] = obj.DatasetDiskCache.LoadPluginResult(plugin_name, context, reporting);
                
                % Check dependencies of the result. If they are invalid, set the
                % result to null to force a re-run of the plugin
                if ~isempty(cache_info)
                    dependencies = cache_info.DependencyList;
                    if ~PTKPluginDependencyTracker.CheckDependenciesValid(linked_dataset_chooser, dependencies, reporting)
                        reporting.ShowWarning('PTKPluginDependencyTracker:InvalidDependency', ['The cached value for plugin ' plugin_name ' is no longer valid since some of its dependencies have changed. I am forcing this plugin to re-run to generate new results.'], []);
                        result = [];
                    end
                end
                
                % Add the dependencies of the cached result to any other
                % plugins in the callstack
                if ~isempty(result) && ~isempty(cache_info)
                    dependencies = cache_info.DependencyList;
                    dataset_stack.AddDependenciesToAllPluginsInStack(dependencies);
                    
                    dependency = cache_info.InstanceIdentifier;
                    dependency_list_for_this_plugin = PTKDependencyList;
                    dependency_list_for_this_plugin.AddDependency(dependency, reporting);
                    dataset_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_this_plugin);
                end
                
            end
            
            % Run the plugin
            if isempty(result)
                plugin_has_been_run = true;
                
                ignore_dependency_checks = plugin_info.AlwaysRunPlugin || ~allow_results_to_be_cached;
                
                % Pause the self-timing of the current plugin
                dataset_stack.PauseTiming;                

                % Create a new dependency. The dependency relates to the plugin
                % being called (plugin_name) and the UID of the dataset the
                % result is being requested from; however, the stack belongs to
                % the primary dataset
                dataset_stack.CreateAndPush(plugin_name, context, dataset_uid, ignore_dependency_checks, false, PTKSoftwareInfo.TimeFunctions);
                
                dataset_callback = PTKDatasetCallback(linked_dataset_chooser, dataset_stack, context);

                % This is the actual call which runs the plugin
                if strcmp(plugin_info.PTKVersion, '1')
                    result = plugin_class.RunPlugin(dataset_callback, reporting);
                else
                    result = plugin_class.RunPlugin(dataset_callback, context, reporting);
                end
                
                new_cache_info = dataset_stack.Pop;
                
                if PTKSoftwareInfo.TimeFunctions
                    dataset_stack.ResumeTiming;
                end
                
                if ~strcmp(plugin_name, new_cache_info.InstanceIdentifier.PluginName)
                    reporting.Error('PTKPluginDependencyTracker:GetResult', 'Inconsistency in plugin call stack. To resolve this error, try deleting the cache for this dataset.');
                end
                
                % Get the newly calculated list of dependencies for this
                % plugin
                dependencies = new_cache_info.DependencyList;
                
                % Cache the plugin result
                if allow_results_to_be_cached && ~isempty(result)
                    obj.DatasetDiskCache.SavePluginResult(plugin_name, result, new_cache_info, context, reporting);
                else
                    obj.DatasetDiskCache.CachePluginInfo(plugin_name, new_cache_info, context, false, reporting);
                end
                
                dataset_stack.AddDependenciesToAllPluginsInStack(dependencies);
                
                dependency = new_cache_info.InstanceIdentifier;
                dependency_list_for_this_plugin = PTKDependencyList;
                dependency_list_for_this_plugin.AddDependency(dependency, reporting);
                dataset_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_this_plugin);
                
                cache_info = new_cache_info;
            else
                plugin_has_been_run = false;
            end
            
            % Fetch the edited result, if it exists
            if obj.DatasetDiskCache.EditedResultExists(plugin_name, context, reporting)
                [edited_result, edited_cache_info] = obj.DatasetDiskCache.LoadEditedPluginResult(plugin_name, context, reporting);

                % Call the plugin to create an edited output
                result = plugin_class.GetEditedResult(result, edited_result, reporting);
                
                % Get the dependency for this edit and add to calling functions
                edited_dependency = edited_cache_info.InstanceIdentifier;
                dependency_list_for_edit = PTKDependencyList;
                dependency_list_for_edit.AddDependency(edited_dependency, reporting);
                dataset_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_edit);
                cache_info.MarkEdited;
            end
        end

        function SaveEditedResult(obj, plugin_name, context, result, dataset_uid, reporting)
            % Saves the result of a plugin after semi-automatic editing
            
            attributes = [];
            attributes.IgnoreDependencyChecks = false;
            attributes.IsEditedResult = true;
            instance_identifier = PTKDependency(plugin_name, context, PTKSystemUtilities.GenerateUid, dataset_uid, attributes);
            new_cache_info = PTKDatasetStackItem(instance_identifier, PTKDependencyList, false, false, reporting);
            new_cache_info.MarkEdited;

            obj.DatasetDiskCache.SaveEditedPluginResult(plugin_name, context, result, new_cache_info, reporting);
        end
        
        function [valid, edited_result_exists] = CheckDependencyValid(obj, next_dependency, reporting)
            [valid, edited_result_exists] = obj.DatasetDiskCache.CheckDependencyValid(next_dependency, reporting);
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
    
    methods (Static, Access = private)
        
        % Checks the dependencies in this result with the current dependency
        % list, and determine if the dependencies are still valid
        function valid = CheckDependenciesValid(linked_dataset_chooser, dependencies, reporting)
            
            dependency_list = dependencies.DependencyList;

            % Build up a list of dependencies which are edited values
            known_edited_values = {};
            for index = 1 : length(dependency_list)
                next_dependency = dependency_list(index);
                if isfield(next_dependency.Attributes, 'IsEditedResult') && (next_dependency.Attributes.IsEditedResult)
                    known_edited_values{end + 1} = next_dependency.PluginName;
                end
            end
            
            for index = 1 : length(dependency_list)
                next_dependency = dependency_list(index);
                
                dataset_uid = next_dependency.DatasetUid;
                [valid, edited_result_exists] = linked_dataset_chooser.GetDataset(dataset_uid).CheckDependencyValid(next_dependency);
                if ~valid
                    valid = false;
                    return;
                end
                
                % If the dependency is based on a non-edited result, but we have an edited
                % result in the cache, then this plugin result is invalid
                if edited_result_exists && ~ismember(next_dependency.PluginName, known_edited_values)
                    reporting.Log(['The result for dependency ' next_dependency.PluginName '(' char(next_dependency.Context) ') has been edited - forcing re-run for plugin.']);
                    valid = false;
                    return;
                end
            end
            
            valid = true;
        end
        
    end    
end

