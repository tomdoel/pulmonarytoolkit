classdef TDDependencyList < handle
    % TDDependency. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     TDDependencyList stores a list of dependencies (TDDependency objects) 
    %     for a particular plugin result, for a particular dataset. 
    %     Each dependency represents another 
    %     plugin result which was accessed during the generation of this result. 
    %     These are used to ensure that any given result is still valid, by 
    %     ensuring that the dependency list matches the dependencies currently 
    %     held in the cache for each plugin.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        DependencyList % Store the list of dependencies
    end
    
    methods
        function obj = TDDependencyList
            obj.DependencyList = TDDependency.empty;
        end
        
        % Adds a single dependency to the list
        function AddDependency(obj, dependency, reporting)
            if ~obj.DependencyAlreadyExists(dependency, reporting)
                obj.DependencyList(end+1) = dependency;
            end
        end
        
        % Adds multiple dependencies to the list
        function AddDependenciesList(obj, dependencies, reporting)
            new_dependency_list = dependencies.DependencyList;
            for index = 1 : length(new_dependency_list);
                obj.AddDependency(new_dependency_list(index), reporting);
            end
        end
        
    end
    
    methods (Access = private)
        
        % Check if this dependency already exists
        function dependency_exists = DependencyAlreadyExists(obj, new_dependency, reporting)
            for index = 1 : length(obj.DependencyList)
                dependency = obj.DependencyList(index);
                
                if strcmp(dependency.PluginName, new_dependency.PluginName) && strcmp(dependency.DatasetUid, new_dependency.DatasetUid)
                    dependency_exists = true;
                    if ~strcmp(dependency.Uid, new_dependency.Uid)
                        if (dependency.Attributes.IgnoreDependencyChecks && new_dependency.Attributes.IgnoreDependencyChecks)
                            reporting.ShowWarning('TDDependencyList:PermittedDependencyMismatch', ['A dependency mismatch for plugin ' dependency.PluginName ' was ignored because the plugin has been set to always run or not to cache results. This dependency mismatch indicates a possible inefficiency in the code as the plugin has been run more than once.'], []);
                        else
                            reporting.Error('TDDependencyList:DependencyMismatch', ['Dependency mismatch found for plugin ' dependency.PluginName '. You can fix this by clearing the cache for this datset.']);
                        end
                    end
                    return;
                end
            end
            dependency_exists = false;
        end
        
    end
end