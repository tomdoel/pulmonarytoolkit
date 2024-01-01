classdef MimDatasetStack < handle
    % Used to build up a list of dependencies for a plugin. A plugin may
    % call other plugins during its execution, so a dependency list needs to
    % be built up in a recursive manner, and include plugins called both
    % directly and indirectly, hence we use a stack.
    %
    % When a plugin is called, it is given an empty dependency list, and is 
    % added to the plugin call stack. If there are any other plugins on the 
    % stack, this plugin is added to the dependency list of each of those
    % plugins. When a plugin finished its execution, it is removed from the
    % call stack, and its dependency list is stored. This list should now
    % contain a complete list of plugins called both directly and indirectly
    % during execution of the plugin. Note that when a plugin
    % result is retrieved from the disk cache, its dependencies must still
    % be added to any plugins on the call stack, to ensure dependency lists
    % are complete.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        
        % The stack - an array of MimDatasetStackItem objects; one for each plugin which is
        % currently being executed.
        DatasetStack
        
        % Stack of MimParameters. Each plugin call creates a new entry;
        % current parameter values are found by traversing the stack in reverse
        ParameterStack
        
        ClassFactory % We store a class factory for creating new MimDatasetStackItem objects
    end
    
    methods
        function obj =  MimDatasetStack(class_factory)
            obj.ClassFactory = class_factory;
            obj.DatasetStack = obj.ClassFactory.CreateEmptyDatasetStackItem();
            obj.ParameterStack = MimParameters.empty();
        end
    
        function CreateAndPush(obj, plugin_name, context, parameters, dataset_uid, ignore_dependency_checks, is_edited_result, start_timer, plugin_version, reporting)
            % Create a new MimDatasetStackItem object with an empty dependency list and a
            % new unique identifier. The push it to the end of the stack
        
            if obj.PluginAlreadyExistsInStack(plugin_name, context, dataset_uid)
                reporting.Error('MimDatasetStack:RecursivePluginCall', 'Recursive plugin call');
            end
            attributes = [];
            attributes.IgnoreDependencyChecks = ignore_dependency_checks;
            attributes.IsEditedResult = is_edited_result;
            attributes.PluginVersion = plugin_version;
            instance_identifier = PTKDependency(plugin_name, context, CoreSystemUtilities.GenerateUid, dataset_uid, attributes);
            cache_info = obj.ClassFactory.CreateDatasetStackItem(instance_identifier, PTKDependencyList(), ignore_dependency_checks, start_timer, reporting);
            obj.DatasetStack(end + 1) = cache_info;
            if isempty(parameters)
                parameters = MimParameters();
            end
            obj.ParameterStack(end + 1) = parameters;
        end
        
        function value = GetParameterAndAddDependenciesToPluginsInStack(obj, name, reporting)
        
            [value, found_index] = obj.GetCurrentParameterValue(name, reporting);
            attributes = [];
            attributes.IsParameter = true;
            instance_identifier = PTKDependency(name, [], value, value, attributes);
            
            % We add a dependency to all plugins up to the level where the
            % parameter was defined
            dependency_list_for_this_parameter = PTKDependencyList();
            dependency_list_for_this_parameter.AddDependency(instance_identifier, reporting);            
            obj.AddDependenciesToPluginsInStack(dependency_list_for_this_parameter, found_index, reporting)
        end
        
        function cache_info = Pop(obj)
            % Remove a plugin from the call stack and return the updated info object
            % for this plugin
        
            cache_info = obj.DatasetStack(end);
            cache_info.StopAndDeleteTimer;
            obj.DatasetStack(end) = [];
            obj.ParameterStack(end) = [];
        end
        
        function AddDependenciesToAllPluginsInStack(obj, dependencies, reporting)
            % Adds the specified plugin as a dependency of every plugin which is
            % currently being executed in the call stack

            obj.AddDependenciesToPluginsInStack(dependencies, 1, reporting);
        end
        
        function ClearStack(obj)
            % Clear the stack. This may be necessary if a plugin failed during
            % execution, leaving the call stack in a bad state.
        
            obj.DatasetStack = obj.ClassFactory.CreateEmptyDatasetStackItem();
            obj.ParameterStack = MimParameters.empty();
        end
        
        function PauseTiming(obj)
            % Pause the timer used to generate SelfTime for the most recent plugin
            % on the stack
            if ~isempty(obj.DatasetStack) && ~isempty(obj.DatasetStack(end).ExecutionTimer)
                obj.DatasetStack(end).ExecutionTimer.Pause();
            end
        end

        function ResumeTiming(obj)
            % Resume the timer used to generate SelfTime for the most recent plugin
            % on the stack
        
            if ~isempty(obj.DatasetStack) && ~isempty(obj.DatasetStack(end).ExecutionTimer)
                obj.DatasetStack(end).ExecutionTimer.Resume();
            end
        end
        
        function plugin_exists = PluginAlreadyExistsInStack(obj, plugin_name, context, this_dataset_uid)
            % Check if this plugin already exists in the stack
        
            for index = 1 : length(obj.DatasetStack)
                plugin_info = obj.DatasetStack(index);
                this_name = plugin_info.InstanceIdentifier.PluginName;
                this_context = plugin_info.InstanceIdentifier.Context;
                if strcmp(plugin_name, this_name) && strcmp(plugin_info.InstanceIdentifier.DatasetUid, this_dataset_uid)
                    % If both contexts are null we consider this equality - but
                    % Matlab does not consider 2 null values to be equal so we
                    % check for this case explicitly
                    if (CoreCompareUtilities.CompareEnumName(context, this_context)) || (isempty(context) && isempty(this_context))
                        plugin_exists = true;
                        return;
                    end
                end
            end
            plugin_exists = false;
        end

        function valid = CheckParameterDependencies(obj, parameter_list, parameters_for_next_plugin_call, reporting)
            for index = 1 : length(parameter_list)
                next_parameter = parameter_list{index};
                parameter_name = next_parameter.PluginName;
                if ~isempty(parameters_for_next_plugin_call) && parameters_for_next_plugin_call.IsField(parameter_name)
                    current_value = parameters_for_next_plugin_call.(parameter_name);
                else
                    current_value = obj.GetCurrentParameterValue(parameter_name, reporting);
                end
                if ~isequal(current_value, next_parameter.DatasetUid)
                    valid = false;
                    disp(['Different parameter value found for ' parameter_name]);
                    return;
                end
            end
            valid = true;
        end
    end
    
    methods (Access = private)
        function [value, found_index] = GetCurrentParameterValue(obj, name, reporting)
            param_found = false;
            found_index = length(obj.ParameterStack);
            for found_index = found_index : -1 : 1
                param_set = obj.ParameterStack(found_index);
                if param_set.IsField(name)
                    value = param_set.(name);
                    param_found = true;
                    break;
                end
            end
            if ~param_found
                value = [];
                reporting.Error('MimDatasetStack:UnknownParamater', 'No parameter has been set with this name');
            end
        end
        
        function AddDependenciesToPluginsInStack(obj, dependencies, first_index, reporting)
            % Adds the specified dependencies to the dependencies of all
            % plugins in the stack from the specified index onwards
            
            for index = length(obj.DatasetStack) : -1 : first_index
                dataset_stack_item = obj.DatasetStack(index);
                dataset_stack_item.AddDependencies(dependencies, reporting);
            end
        end
    end
end