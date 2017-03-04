classdef MimPluginDependencyTracker < CoreBaseClass
    % MimPluginDependencyTracker. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     MimPluginDependencyTracker is used by MimDataset to fetch plugin results
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    properties
        DatasetDiskCache % Loads and saves data associated with this dataset
        FrameworkAppDef % Framework configuration
        PluginCache % Used to check plugin version numbers
    end
    
    methods
        
        function obj = MimPluginDependencyTracker(framework_app_def, dataset_disk_cache, plugin_cache)
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.FrameworkAppDef = framework_app_def;
            obj.PluginCache = plugin_cache;
        end
        
        function [result, plugin_has_been_run, cache_info] = GetResult(obj, plugin_name, context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, memory_cache_policy, disk_cache_policy, reporting)
            % Gets a plugin result, from the disk cache if possible. If there is no
            % cached result, or if the dependencies are invalid, or if the
            % "AlwaysRunPlugin" property is set, then the plugin is executed.
        
            % Fetch plugin result from the disk cache
            result = [];
            edited_result = [];
            
            edited_result_exists = obj.DatasetDiskCache.EditedResultExists(plugin_name, context, reporting);
            
            % We can skip fetching the result if an edited result exists
            % and does not depend on the automated result
            if ~edited_result_exists || plugin_info.EditRequiresPluginResult

                if ~plugin_info.AlwaysRunPlugin
            
                    [result, cache_info] = obj.DatasetDiskCache.LoadPluginResult(plugin_name, context, memory_cache_policy, reporting);

                    % Check dependencies of the result. If they are invalid, set the
                    % result to null to force a re-run of the plugin
                    if ~isempty(cache_info)
                        dependencies = cache_info.DependencyList;
                        if ~obj.CheckPluginVersion(cache_info.InstanceIdentifier, reporting)
                            reporting.ShowWarning('MimPluginDependencyTracker:InvalidDependency', ['The plugin ' plugin_name ' has changed since the cache was generated. I am forcing this plugin to re-run to generate new results.'], []);
                            result = [];
                        end

                        if ~obj.CheckDependenciesValid(linked_dataset_chooser, dependencies, reporting)
                            reporting.ShowWarning('MimPluginDependencyTracker:InvalidDependency', ['The cached value for plugin ' plugin_name ' is no longer valid since some of its dependencies have changed. I am forcing this plugin to re-run to generate new results.'], []);
                            result = [];
                        end
                    end
                
                    % Add the dependencies of the cached result to any other
                    % plugins in the callstack
                    if ~isempty(result) && ~isempty(cache_info)
                        dependencies = cache_info.DependencyList;
                        dataset_stack.AddDependenciesToAllPluginsInStack(dependencies, reporting);

                        dependency = cache_info.InstanceIdentifier;
                        dependency_list_for_this_plugin = PTKDependencyList();
                        dependency_list_for_this_plugin.AddDependency(dependency, reporting);
                        dataset_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_this_plugin, reporting);
                    end

                end

                % Run the plugin
                if isempty(result)
                    plugin_has_been_run = true;

                    % At present we ignore dependency checks if the results are
                    % not permanently cached to disk. This is to ensure we
                    % don't get dependency check errors when a plugin is
                    % fetched twice (by two different plugins) and has to be
                    % generated twice becase the result is not cached.
                    ignore_dependency_checks = plugin_info.DiskCachePolicy ~= MimCachePolicy.Permanent;

                    % Pause the self-timing of the current plugin
                    dataset_stack.PauseTiming;                

                    % Create a new dependency. The dependency relates to the plugin
                    % being called (plugin_name) and the UID of the dataset the
                    % result is being requested from; however, the stack belongs to
                    % the primary dataset
                    plugin_version = plugin_info.PluginVersion;
                    dataset_stack.CreateAndPush(plugin_name, context, dataset_uid, ignore_dependency_checks, false, obj.FrameworkAppDef.TimeFunctions, plugin_version, reporting);

                    dataset_callback = MimDatasetCallback(linked_dataset_chooser, dataset_stack, context, reporting);
                    
                    try
                        % This is the actual call which runs the plugin
                        if strcmp(plugin_info.PluginInterfaceVersion, '1')
                            result = plugin_class.RunPlugin(dataset_callback, reporting);
                        else
                            result = plugin_class.RunPlugin(dataset_callback, context, reporting);
                        end

                        new_cache_info = dataset_stack.Pop;

                        if obj.FrameworkAppDef.TimeFunctions
                            dataset_stack.ResumeTiming;
                        end

                        if ~strcmp(plugin_name, new_cache_info.InstanceIdentifier.PluginName)
                            reporting.Error('MimPluginDependencyTracker:GetResult', 'Inconsistency in plugin call stack. To resolve this error, try deleting the cache for this dataset.');
                        end

                        % Get the newly calculated list of dependencies for this
                        % plugin
                        dependencies = new_cache_info.DependencyList;

                        % Cache the plugin result according to the specified cache policies
                        obj.DatasetDiskCache.SavePluginResult(plugin_name, result, new_cache_info, context, disk_cache_policy, memory_cache_policy, reporting);
    
                        dataset_stack.AddDependenciesToAllPluginsInStack(dependencies, reporting);

                        dependency = new_cache_info.InstanceIdentifier;
                        dependency_list_for_this_plugin = PTKDependencyList();
                        dependency_list_for_this_plugin.AddDependency(dependency, reporting);
                        dataset_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_this_plugin, reporting);

                        cache_info = new_cache_info;
                    catch ex
                            % For certain plugins we throw a special exception
                            % which indicates that the user should be offered
                            % the ability to create a manual edit
                            if plugin_info.SuggestManualEditOnFailure
                                throw(MimSuggestEditException(plugin_name, context, ex, CoreTextUtilities.RemoveHtml(plugin_class.ButtonText)));
                            else
                                rethrow(ex);
                            end
                    end        

                else
                    plugin_has_been_run = false;
                end
                
            else
                cache_info = [];
                plugin_has_been_run = false;
            end
            
            % Fetch the edited result, if it exists
            if edited_result_exists
                
                [edited_result, edited_cache_info] = obj.DatasetDiskCache.LoadEditedPluginResult(plugin_name, context, reporting);
                
                % If the edited result does not depend on the automated
                % result, we won't have (and don't need) cache info for the
                % plugin result so just use the edited result
                if isempty(cache_info)
                    cache_info = edited_cache_info;
                end
                
                % In case the cache is out of sync with the existance of
                % the edited result, this will update the cache
                obj.DatasetDiskCache.UpdateEditedResults(plugin_name, edited_cache_info, context, reporting);

                % Call the plugin to create an edited output
                result = plugin_class.GetEditedResult(result, edited_result, reporting);
                
                % Get the dependency for this edit and add to calling functions
                edited_dependency = edited_cache_info.InstanceIdentifier;
                dependency_list_for_edit = PTKDependencyList();
                dependency_list_for_edit.AddDependency(edited_dependency, reporting);
                dataset_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_edit, reporting);
                cache_info.MarkEdited;
            else
                % In case the cache is out of sync with the existance of
                % the edited result, this will delete the edited result entry from the cache
                obj.DatasetDiskCache.UpdateEditedResults(plugin_name, [], context, reporting);

            end
        end

        function edited_cached_info = SaveEditedResult(obj, plugin_name, context, edited_result, dataset_uid, plugin_version, reporting)
            % Saves the result of a plugin after semi-automatic editing
            
            attributes = [];
            attributes.IgnoreDependencyChecks = false;
            attributes.IsEditedResult = true;
            attributes.PluginVersion = plugin_version;
            instance_identifier = PTKDependency(plugin_name, context, CoreSystemUtilities.GenerateUid, dataset_uid, attributes);
            edited_cached_info = obj.FrameworkAppDef.GetClassFactory.CreateDatasetStackItem(instance_identifier, PTKDependencyList(), false, false, reporting);
            edited_cached_info.MarkEdited;

            obj.DatasetDiskCache.SaveEditedResult(plugin_name, context, edited_result, edited_cached_info, reporting);
        end
                
        function edited_result = GetDefaultEditedResult(obj, context, linked_dataset_chooser, plugin_class, dataset_stack, reporting)
            dataset_callback = MimDatasetCallback(linked_dataset_chooser, dataset_stack, context, reporting);
            edited_result = plugin_class.GenerateDefaultEditedResultFollowingFailure(dataset_callback, context, reporting);
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
        
        % Checks the dependencies in this result with the current dependency
        % list, and determine if the dependencies are still valid
        function valid = CheckDependenciesValid(obj, linked_dataset_chooser, dependencies, reporting)
            
            dependency_list = dependencies.DependencyList;

            % Build up a list of dependencies which are edited values
            known_edited_values = {};
            for index = 1 : length(dependency_list)
                next_dependency = dependency_list(index);
                if ~obj.CheckPluginVersion(next_dependency, reporting)
                    valid = false;
                    reporting.Log(['A newer version of plugin ' next_dependency.PluginName ' has been found. This result must be regenerated.']);
                    return;
                end

                if isfield(next_dependency.Attributes, 'IsEditedResult') && (next_dependency.Attributes.IsEditedResult)
                    known_edited_values{end + 1} = next_dependency.PluginName;
                end
            end
            
            for index = 1 : length(dependency_list)
                next_dependency = dependency_list(index);
                
                dataset_uid = next_dependency.DatasetUid;
                [valid, edited_result_exists] = linked_dataset_chooser.GetDataset(dataset_uid).CheckDependencyValid(next_dependency, reporting);
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
        
        function valid = CheckPluginVersion(obj, next_dependency, reporting)
            if isfield(next_dependency.Attributes, 'PluginVersion')
                dependency_version = next_dependency.Attributes.PluginVersion;
            else
                dependency_version = 1;
            end
            
            plugin_info = obj.PluginCache.GetPluginInfo(next_dependency.PluginName, [], reporting);
            valid = plugin_info.PluginVersion == dependency_version;
        end
    end    
end

