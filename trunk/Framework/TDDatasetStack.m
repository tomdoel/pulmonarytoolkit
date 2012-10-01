classdef TDDatasetStack < handle
    % TDDatasetStack. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Used to build up a list of dependencies for a plugin. A plugin may
    %     call other plugins during its execution, so a dependency list needs to
    %     be built up in a recursive manner, and include plugins called both
    %     directly and indirectly, hence we use a stack.
    %
    %     When a plugin is called, it is given an empty dependency list, and is 
    %     added to the plugin call stack. If there are any other plugins on the 
    %     stack, this plugin is added to the dependency list of each of those
    %     plugins. When a plugin finished its execution, it is removed from the
    %     call stack, and its dependency list is stored. This list should now
    %     contain a complete list of plugins called both directly and indirectly
    %     during execution of the plugin. Note that when a plugin
    %     result is retrieved from the disk cache, its dependencies must still
    %     be added to any plugins on the call stack, to ensure dependency lists
    %     are complete.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        
        % The stack - an array of TDDatasetStackItem objects; one for each plugin which is
        % currently being executed.
        DatasetStack

        % Callback for errors, warnings and logs
        Reporting
    end
    
    methods
        function obj =  TDDatasetStack(reporting)
            obj.DatasetStack = TDDatasetStackItem.empty;
            obj.Reporting = reporting;
        end
    
        % Create a new TDDatasetStackItem object with an empty dependency list and a
        % new unique identifier. The push it to the end of the stack
        function CreateAndPush(obj, plugin_name, dataset_uid, ignore_dependency_checks)
            if obj.PluginAlreadyExistsInStack(plugin_name)
                obj.Reporting.Error('TDDatasetStack:RecursivePluginCall', 'Recursive plugin call');
            end
            attributes = [];
            attributes.IgnoreDependencyChecks = ignore_dependency_checks;
            instance_identifier = TDDependency(plugin_name, TDDiskUtilities.GenerateUid, dataset_uid, attributes);
            cache_info = TDDatasetStackItem(instance_identifier, TDDependencyList, ignore_dependency_checks, obj.Reporting);
            obj.DatasetStack(end + 1) = cache_info;
        end
        
        % Remove a plugin from the call stack and return the updated info object
        % for this plugin
        function cache_info = Pop(obj)
            cache_info = obj.DatasetStack(end);
            obj.DatasetStack(end) = [];
        end
        
        % Adds the specified plugin as a dependency of every plugin which is
        % currently being executed in the call stack
        function AddDependenciesToAllPluginsInStack(obj, dependencies)
            for index = 1 : length(obj.DatasetStack)
                dataset_stack_item = obj.DatasetStack(index);
                dataset_stack_item.AddDependencies(dependencies, obj.Reporting);
            end
        end
        
        % Clear the stack. This may be necessary if a plugin failed during
        % execution, leaving the call stack in a bad state.
        function ClearStack(obj)
            obj.DatasetStack = TDDatasetStackItem.empty;
        end

    end
    
    methods (Access = private)
        
        % Check if this plugin already exists in the stack
        function plugin_exists = PluginAlreadyExistsInStack(obj, plugin_name)
            for index = 1 : length(obj.DatasetStack)
                plugin_info = obj.DatasetStack(index);
                this_name = plugin_info.InstanceIdentifier.PluginName;
                if strcmp(plugin_name, this_name)
                    plugin_exists = true;
                    return;
                end
            end
            plugin_exists = false;
        end
        
    end
    
end

