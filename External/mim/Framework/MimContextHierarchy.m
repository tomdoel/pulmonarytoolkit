classdef MimContextHierarchy < CoreBaseClass
    % MimContextHierarchy. Part of the internal framework of the TD MIM Toolkit.
    %
    %     This class is used to switch beteen different contexts.
    %
    %     There are a number of contexts, which each represent particular
    %     regions of the lung. For example, the OriginalImage context is the
    %     entire image, whereas the LungROI is the parrallipiped region
    %     containing the lungs and airways. The LeftLung and RightLung comprise
    %     just the voumes of the left and right lung respectively.
    %
    %     Context sets describe a collection of related contexts. For example,
    %     the SingleLung context set contains LeftLung and RightLung.
    %
    %     Each plugin specifies its context set, which is the domain of the
    %     results produced by the plugin. Some plugins operate over the whole
    %     LungROI region, while some operate on individual lungs.
    %
    %     This class manages the situations where a result is requested for a
    %     particualar context (e.g. LungROI) but the plugin defines a different
    %     context set (e.g. SingleLung). The LungROI can be built from the two
    %     contexts in the SingleLung set. Therefore in this case, the plugin is run twice,
    %     once for the left and once for the right lung. Then the resutls are
    %     combined to produce the result for the LungROI context.
    %
    %     Thie class manages this heirarchy of contexts and context sets. In
    %     this way plugins can operate on whichever context is appropriate,
    %     while results can be requested for any context, and the conversions
    %     are handled automatically.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    
    properties
        ContextSets
        Contexts
        ContextDef
        
        DatasetDiskCache
        ImageTemplates
        Pipelines
        FrameworkAppDef % Framework configuration
        PluginCache % Used to check plugin version numbers        
    end
    
    methods
        function obj = MimContextHierarchy(context_def, dataset_disk_cache, image_templates, pipelines, framework_app_def, plugin_cache)
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.ImageTemplates = image_templates;
            obj.Pipelines = pipelines;
            obj.FrameworkAppDef = framework_app_def;
            obj.PluginCache = plugin_cache;
            
            obj.ContextDef = context_def;
            obj.Contexts = context_def.GetContexts;
            obj.ContextSets = context_def.GetContextSets;
        end
        
        function context_list = GetContextList(obj, output_context, plugin_info, reporting)
            % Parses a list of Contexts, expands out any ContextSets into
            % Contexts, and returns an error if a Context is not known
            
            % Determines the context and context type requested by the calling function
            if isempty(output_context)
                output_context = obj.ContextDef.ChooseOutputContext(plugin_info.Context);
            end
            
            context_list = [];
            
            for next_output_context_set = CoreContainerUtilities.ConvertToSet(output_context)
                next_output_context = next_output_context_set{1};
                if obj.Contexts.isKey(char(next_output_context))
                    % Note that if the enum name of the context set matches
                    % the enum name of a context, we need to be sure the
                    % contet gets added, not the context set
                    context_list{end + 1} = obj.Contexts(char(next_output_context)).Context;
                elseif obj.ContextSets.isKey(char(next_output_context))
                    context_set_mapping = obj.ContextSets(char(next_output_context));
                    context_mapping_list = context_set_mapping.ContextList;
                    context_list = [context_list, CoreContainerUtilities.GetFieldValuesFromSet(context_mapping_list, 'Context')];
                else
                    if obj.DatasetDiskCache.ManualSegmentationExists(char(next_output_context), reporting)
                        context_list{end + 1} = char(next_output_context);
                    else
                        % Allow contexts with specific label indices
                        [context_prefix, context_suffix] = CoreTextUtilities.SplitAtLastDelimiter(char(next_output_context), '.');
                        if obj.DatasetDiskCache.ManualSegmentationExists(context_prefix, reporting)
                            context_list{end + 1} = char(next_output_context);
                        else
                            reporting.Error('MimContextHierarchy:UnknownOutputContext', 'I do not understand the requested output context.');
                        end
                    end
                end
            end            
        end
        
        function value = GetParameter(obj, name, dataset_stack, reporting)
            value = dataset_stack.GetParameterAndAddDependenciesToPluginsInStack(name, reporting);
        end
        
        function combined_result = GetResultRecursive(obj, plugin_name, output_context, parameters, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, memory_cache_policy, disk_cache_policy, reporting)
            
            % Records that there has been an attempt to call this plugin,
            % so that we can detect if a plugin call failed
            obj.ImageTemplates.NoteAttemptToRunPlugin(plugin_name, output_context, reporting);

            [plugin_context_set, plugin_context_set_mapping] = obj.GetContextSetMappings(plugin_info.Context);            
            [output_context, output_context_set, output_context_mapping, output_context_set_mapping] = obj.GetContextMaps(output_context);
            
            % If the input and output contexts are of the same type, or if the
            % plugin context is of type 'Any', then proceed to call the plugin
            if isempty(output_context_set) || obj.ContextDef.ContextSetMatches(plugin_context_set, output_context_set)
                
                
                % Code moved from PluginDependencyTracker
                
                
                % Fetch plugin result from the disk cache
                result = [];

                edited_result_exists = obj.DatasetDiskCache.EditedResultExists(plugin_name, output_context, reporting);

                % We can skip fetching the result if an edited result exists
                % and does not depend on the automated result
                if ~edited_result_exists || plugin_info.EditRequiresPluginResult

                    if ~plugin_info.AlwaysRunPlugin

                        [result, cache_info] = obj.DatasetDiskCache.LoadPluginResult(plugin_name, output_context, memory_cache_policy, reporting);

                        % Check dependencies of the result. If they are invalid, set the
                        % result to null to force a re-run of the plugin
                        if ~isempty(cache_info)
                            dependencies = cache_info.DependencyList;
                            if ~obj.CheckPluginVersion(cache_info.InstanceIdentifier, reporting)
                                reporting.ShowWarning('MimContextHierarchy:InvalidDependency', ['The plugin ' plugin_name ' has changed since the cache was generated. I am forcing this plugin to re-run to generate new results.'], []);
                                result = [];
                            end

                            if ~obj.CheckDependenciesValid(linked_dataset_chooser, dependencies, dataset_stack, parameters, reporting)
                                reporting.ShowWarning('MimContextHierarchy:InvalidDependency', ['The cached value for plugin ' plugin_name ' is no longer valid since some of its dependencies have changed. I am forcing this plugin to re-run to generate new results.'], []);
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
                        reporting.ReleaseDelay();
                        reporting.UpdateProgressMessage(['Computing ' plugin_info.ButtonText]);

                        
                        plugin_has_been_run = true;

                        % At present we ignore dependency checks if the results are
                        % not permanently cached to disk. This is to ensure we
                        % don't get dependency check errors when a plugin is
                        % fetched twice (by two different plugins) and has to be
                        % generated twice becase the result is not cached.
                        ignore_dependency_checks = plugin_info.DiskCachePolicy ~= MimCachePolicy.Permanent;

                        % Pause the self-timing of the current plugin
                        dataset_stack.PauseTiming();                

                        % Create a new dependency. The dependency relates to the plugin
                        % being called (plugin_name) and the UID of the dataset the
                        % result is being requested from; however, the stack belongs to
                        % the primary dataset
                        plugin_version = plugin_info.PluginVersion;
                        dataset_stack.CreateAndPush(plugin_name, output_context, parameters, dataset_uid, ignore_dependency_checks, false, obj.FrameworkAppDef.TimeFunctions, plugin_version, reporting);

                        dataset_callback = MimDatasetCallback(linked_dataset_chooser, dataset_stack, output_context, reporting);

                        try
                            % This is the actual call which runs the plugin
                            if strcmp(plugin_info.PluginInterfaceVersion, '1')
                                result = plugin_class.RunPlugin(dataset_callback, reporting);
                            else
                                result = plugin_class.RunPlugin(dataset_callback, output_context, reporting);
                            end

                            new_cache_info = dataset_stack.Pop;

                            if obj.FrameworkAppDef.TimeFunctions
                                dataset_stack.ResumeTiming;
                            end

                            if ~strcmp(plugin_name, new_cache_info.InstanceIdentifier.PluginName)
                                reporting.Error('MimContextHierarchy:GetResult', 'Inconsistency in plugin call stack. To resolve this error, try deleting the cache for this dataset.');
                            end

                            % Get the newly calculated list of dependencies for this
                            % plugin
                            dependencies = new_cache_info.DependencyList;

                            % Cache the plugin result according to the specified cache policies
                            obj.DatasetDiskCache.SavePluginResult(plugin_name, result, new_cache_info, output_context, disk_cache_policy, memory_cache_policy, reporting);

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
                                    throw(MimSuggestEditException(plugin_name, output_context, ex, CoreTextUtilities.RemoveHtml(plugin_class.ButtonText)));
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

                    [edited_result, edited_cache_info] = obj.DatasetDiskCache.LoadEditedPluginResult(plugin_name, output_context, reporting);

                    % If the edited result does not depend on the automated
                    % result, we won't have (and don't need) cache info for the
                    % plugin result so just use the edited result
                    if isempty(cache_info)
                        cache_info = edited_cache_info;
                    end

                    % In case the cache is out of sync with the existance of
                    % the edited result, this will update the cache
                    obj.DatasetDiskCache.UpdateEditedResults(plugin_name, edited_cache_info, output_context, reporting);

                    % Call the plugin to create an edited output
                    result = plugin_class.GetEditedResult(result, edited_result, reporting);

                    % Get the dependency for this edit and add to calling functions
                    edited_dependency = edited_cache_info.InstanceIdentifier;
                    dependency_list_for_edit = PTKDependencyList();
                    dependency_list_for_edit.AddDependency(edited_dependency, reporting);
                    dataset_stack.AddDependenciesToAllPluginsInStack(dependency_list_for_edit, reporting);
                    cache_info.MarkEdited();
                else
                    % In case the cache is out of sync with the existance of
                    % the edited result, this will delete the edited result entry from the cache
                    obj.DatasetDiskCache.UpdateEditedResults(plugin_name, [], output_context, reporting);

                end
                
                % End of code moved from PluginDependencyTracker
                

                
                % If the plugin has been re-run, then we will generate an output
                % image, in order to create a new preview image
                if (plugin_info.GeneratePreview && plugin_has_been_run)
                    force_generate_image = true;
                end

                % We generate an output image if requested, or if the plugin has been re-run (indictaing that we will need to generate a new preview image)
                if force_generate_image
                    output_image = obj.GenerateImageFromResults(result, plugin_class, linked_dataset_chooser, dataset_stack, reporting);
                else
                    output_image = [];
                end

                combined_result = MimCombinedPluginResult(result, output_image, plugin_has_been_run, cache_info);
            
            % Otherwise, if the plugin's context set is higher in the hierarchy
            % than the requested output, then get the result for the higher
            % context and then extract out the desired context
            elseif output_context_set_mapping.IsOtherContextSetHigher(plugin_context_set_mapping)
                combined_result = MimContextResultCombiner(obj.ImageTemplates);
                higher_context_mapping = output_context_mapping.Parent;
                if isempty(higher_context_mapping)
                    reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
                end
                parent_context = higher_context_mapping.Context;
                this_context_results = obj.GetResultRecursive(plugin_name, parent_context, parameters, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, memory_cache_policy, disk_cache_policy, reporting);
                combined_result.AddParentResult(parent_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting);
                
            % If the plugin's context set is lower in the hierarchy, then get
            % the plugin result for all lower contexts and concatenate the results
            elseif plugin_context_set_mapping.IsOtherContextSetHigher(output_context_set_mapping)
                combined_result = MimContextResultCombiner(obj.ImageTemplates);
                child_context_mappings = output_context_mapping.Children;

                for child_mapping = child_context_mappings
                    child_context = child_mapping{1}.Context;
                    this_context_results = obj.GetResultRecursive(plugin_name, child_context, parameters, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, memory_cache_policy, disk_cache_policy, reporting);

                    combined_result.AddChildResult(child_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting);                
                end
            
            else
                reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
            
            % Note that the plugin completed successfully
            obj.ImageTemplates.NoteSuccessRunPlugin(plugin_name, output_context, reporting);
            
            % Allow pipelines to be run if required
            obj.Pipelines.RunPipelines(plugin_name, output_context, parameters, combined_result.GetPluginHasBeenRun, dataset_stack, dataset_uid, reporting);
        end
        
        function SaveEditedResultRecursive(obj, plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting)
            % This function saves a manually edited result which plugins
            % may use to modify their results
            
            % Determines the context and context type requested by the calling function
            if isempty(input_context)
                reporting.Error('MimContextHierarchy:NoContextSpecified', 'When calling SaveEditedResult(), the contex of the input image must be specified.');
                input_context = obj.ContextDef.GetDefaultContext;
            end
            
            [plugin_context_set, plugin_context_set_mapping] = obj.GetContextSetMappings(plugin_info.Context);
        
            [input_context, input_context_set, input_context_mapping, input_context_set_mapping] = obj.GetContextMaps(input_context);
            
            % If the input and output contexts are of the same type, or if the
            % plugin context is of type 'Any', then proceed to save the results
            % for this context.
            if obj.ContextDef.ContextSetMatches(plugin_context_set, input_context_set)
                plugin_version = plugin_info.PluginVersion;
                obj.SaveEditedResult(plugin_name, input_context, edited_result_image, dataset_uid, plugin_version, reporting);

            % Otherwise, if the input's context set is lower in the hierarchy
            % than that of the plugin, then resize the input to match the plugin
            elseif input_context_set_mapping.IsOtherContextSetHigher(plugin_context_set_mapping)
                
                higher_context_mapping = input_context_mapping.Parent;
                if isempty(higher_context_mapping)
                    reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
                end
                parent_context = higher_context_mapping.Context;
                parent_image_template = obj.ImageTemplates.GetTemplateImage(parent_context, dataset_stack, reporting);
                new_edited_image_for_context_image = edited_result_image.Copy;
                new_edited_image_for_context_image.ResizeToMatch(parent_image_template);
                obj.SaveEditedResultRecursive(plugin_name, parent_context, new_edited_image_for_context_image, plugin_info, dataset_stack, dataset_uid, reporting);


            % If the plugin's context set is lower in the hierarchy, then get
            % reduce the edited image input to each lower context in turn and save to each
            elseif plugin_context_set_mapping.IsOtherContextSetHigher(input_context_set_mapping)
                
                child_context_mappings = input_context_mapping.Children;
                
                for child_mapping = child_context_mappings
                    child_context = child_mapping{1}.Context;
                    
                    % Create a new image from the edited result, reduced to this
                    % context
                    new_edited_image_for_context_image = MimReduceResultToContext(edited_result_image, child_mapping{1}.Context, obj.ImageTemplates, dataset_stack, reporting);
                    
                    % Save this new image
                    obj.SaveEditedResultRecursive(plugin_name, child_context, new_edited_image_for_context_image, plugin_info, dataset_stack, dataset_uid, reporting);
                end

            else
                reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
        end
        
        function [valid, edited_result_exists] = CheckDependencyValid(obj, next_dependency, reporting)
            % Checks a given dependency against the cached values to
            % determine if it is valid (ie it depends on the most recent
            % computed results)
            
            plugin_results_info = obj.DatasetDiskCache.GetPluginResultsInfo();

            if isfield(next_dependency.Attributes, 'IsParameter')
                is_parameter = next_dependency.Attributes.IsParameter;
            else
                is_parameter = false;
            end
            % ToDo: process dependency values
            
            if isfield(next_dependency.Attributes, 'IsEditedResult')
                is_edited_result = next_dependency.Attributes.IsEditedResult;
            else
                is_edited_result = false;
            end
            
            if isfield(next_dependency.Attributes, 'IsManualSegmentation')
                is_manual = next_dependency.Attributes.IsManualSegmentation;
            else
                is_manual = false;
            end
            
            if isfield(next_dependency.Attributes, 'IsMarkerSet')
                is_marker = next_dependency.Attributes.IsMarkerSet;
            else
                is_marker = false;
            end
            
            if is_manual
                type_of_dependency = 'manual segmentation';
            else
                type_of_dependency = 'plugin';
            end
            
            edited_result_exists = plugin_results_info.CachedInfoExists(next_dependency.PluginName, next_dependency.Context, MimCacheType.Edited);
            
            if is_edited_result
                cache_type = MimCacheType.Edited;
            elseif is_manual
                cache_type = MimCacheType.Manual;
            elseif is_marker          
                cache_type = MimCacheType.Markers;
            else
                cache_type = MimCacheType.Results;
            end
            
            % The full list should always contain the most recent dependency
            % uid, unless the dependencies file was deleted
            if ~plugin_results_info.CachedInfoExists(next_dependency.PluginName, next_dependency.Context, cache_type)
                reporting.Log(['No dependency record for this ' type_of_dependency ' - forcing re-run.']);
                valid = false;
                return;
            end
            
            current_info = plugin_results_info.GetCachedInfo(next_dependency.PluginName, next_dependency.Context, cache_type);
            current_dependency = current_info.InstanceIdentifier;
            
            if current_info.IgnoreDependencyChecks
                reporting.LogVerbose(['Ignoring dependency checks for ' type_of_dependency ' ' next_dependency.PluginName '(' char(next_dependency.Context) ')']);
            else
                % Sanity check - this case should never occur
                if ~strcmp(next_dependency.DatasetUid, current_dependency.DatasetUid)
                    reporting.Error('MimPluginResultsInfo:DatsetUidError', 'Code error - not matching dataset UID during dependency check');
                end

                if ~strcmp(next_dependency.Uid, current_dependency.Uid)
                    reporting.Log('Mismatch in dependency version uids - forcing re-run');
                    valid = false;
                    return;
                else
                    reporting.LogVerbose(['Dependencies Ok for ' type_of_dependency ' ' next_dependency.PluginName]);
                end
            end
            
            valid = true;
        
        end
        
    end
    
    methods (Access = private)
        
        function valid = CheckDependenciesValid(obj, linked_dataset_chooser, dependencies, dataset_stack, parameters_for_next_plugin_call, reporting)
            % Checks the dependencies in this result with the current dependency
            % list, and determine if the dependencies are still valid
            
            dependency_list = dependencies.DependencyList;

            % Separate dependencies into parameters and plugin
            % dependencies, and also create list of dependencies which are
            % edited values
            plugin_dependencies = {};
            known_edited_values = containers.Map();
            parameter_list = {};
            for index = 1 : length(dependency_list)
                next_dependency = dependency_list(index);
                dataset_uid = next_dependency.DatasetUid;
                if ~known_edited_values.isKey(dataset_uid)
                    known_edited_values(dataset_uid) = {};
                end
                if isfield(next_dependency.Attributes, 'IsParameter') && (next_dependency.Attributes.IsParameter)
                    parameter_list{end + 1} = next_dependency;
                else
                    plugin_dependencies{end + 1} = next_dependency;
                    if ~obj.CheckPluginVersion(next_dependency, reporting)
                        valid = false;
                        reporting.Log(['A newer version of plugin ' next_dependency.PluginName ' has been found. This result must be regenerated.']);
                        return;
                    end                    
                    if isfield(next_dependency.Attributes, 'IsEditedResult') && (next_dependency.Attributes.IsEditedResult)
                        edited_list = known_edited_values(dataset_uid);
                        edited_list{end + 1} = next_dependency.PluginName;
                        known_edited_values(dataset_uid) = edited_list;
                    end
                end
            end
            
            if ~dataset_stack.CheckParameterDependencies(parameter_list, parameters_for_next_plugin_call, reporting)
                valid = false;
                return;
            end
            
            % Iterate through plugin dependencies
            for index = 1 : length(plugin_dependencies)
                next_dependency = plugin_dependencies{index};
                
                dataset_uid = next_dependency.DatasetUid;
                [valid, edited_result_exists] = linked_dataset_chooser.GetDataset(reporting, dataset_uid).CheckDependencyValid(next_dependency, reporting);
                if ~valid
                    valid = false;
                    return;
                end
                
                % If the dependency is based on a non-edited result, but we have an edited
                % result in the cache, then this plugin result is invalid
                if edited_result_exists && ~ismember(next_dependency.PluginName, known_edited_values(dataset_uid))
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

        function [context_set, context_set_mapping] = GetContextSetMappings(obj, context)
            % Determines the type of context supported by the plugin

            context_set = context;
            if isempty(context_set)
                    context_set = obj.ContextDef.GetDefaultContextSet();
            end
            context_set_mapping = obj.ContextSets(char(context_set));
        end

        function [context, context_set, context_mapping, context_set_mapping] = GetContextMaps(obj, context)
            % Determines the context and context type requested by the calling function

            if isempty(context)
                context = obj.ContextDef.GetDefaultContext();
            end
            if obj.Contexts.isKey(char(context))
                context_mapping = obj.Contexts(char(context));
                context_set_mapping = context_mapping.ContextSet;
                context_set = context_set_mapping.ContextSet;
            else
                context_mapping = [];
                context_set_mapping = [];
                context_set = [];
            end
        end
        
        function output_image = GenerateImageFromResults(obj, result, plugin_class, linked_dataset_chooser, dataset_stack, reporting)
            template_callback = MimTemplateCallback(linked_dataset_chooser, dataset_stack, reporting);

            if isa(result, 'PTKImage')
                output_image = plugin_class.GenerateImageFromResults(result.Copy, template_callback, reporting);
            else
                output_image = plugin_class.GenerateImageFromResults(result, template_callback, reporting);
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
            edited_cached_info.MarkEdited();

            obj.DatasetDiskCache.SaveEditedResult(plugin_name, context, edited_result, edited_cached_info, reporting);
        end        
    end
end 

