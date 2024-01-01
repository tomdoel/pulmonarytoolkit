classdef PTKDependencyList < handle
    % Stores a list of dependencies (PTKDependency objects) 
    % for a particular plugin result, for a particular dataset. 
    % Each dependency represents another 
    % plugin result which was accessed during the generation of this result. 
    % These are used to ensure that any given result is still valid, by 
    % ensuring that the dependency list matches the dependencies currently 
    % held in the cache for each plugin.
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        DependencyList % Store the list of dependencies
    end
    
    methods
        function obj = PTKDependencyList(dependency_list)
            if (nargin > 0)
                obj.DependencyList = dependency_list;
            else
                obj.DependencyList = PTKDependency.empty;
            end
        end
        
        function AddDependency(obj, dependency, reporting)
            % Adds a single dependency to the list
        
            if ~obj.DependencyAlreadyExists(dependency, reporting)
                obj.DependencyList(end+1) = dependency;
            end
        end
        
        function AddDependenciesList(obj, dependencies, reporting)
            % Adds multiple dependencies to the list
            
            new_dependency_list = dependencies.DependencyList;
            for index = 1 : length(new_dependency_list)
                obj.AddDependency(new_dependency_list(index), reporting);
            end
        end
        
    end
    
    methods (Access = private)
        
        function dependency_exists = DependencyAlreadyExists(obj, new_dependency, reporting)
            % Check if this dependency already exists
            
            for index = 1 : length(obj.DependencyList)
                dependency = obj.DependencyList(index);
                
                if strcmp(dependency.PluginName, new_dependency.PluginName) && strcmp(dependency.DatasetUid, new_dependency.DatasetUid) && CoreCompareUtilities.CompareEnumName(dependency.Context, new_dependency.Context)
                    if strcmp(dependency.Uid, new_dependency.Uid)
                        dependency_exists = true;
                        return;
                    else
                         if isfield(dependency.Attributes, 'IsEditedResult') && isfield(new_dependency.Attributes, 'IsEditedResult') && (dependency.Attributes.IsEditedResult ~= new_dependency.Attributes.IsEditedResult)
                            reporting.LogVerbose(['Accepting duplicate dependency due to edited result for ' dependency.PluginName]);
                         else
                             if (dependency.Attributes.IgnoreDependencyChecks && new_dependency.Attributes.IgnoreDependencyChecks)
                                 dependency_exists = true;
                                 reporting.LogVerbose(['A dependency mismatch for plugin ' dependency.PluginName ' was ignored because the plugin has been set to always run or not to cache results. This dependency mismatch indicates a possible inefficiency in the code as the plugin has been run more than once.']);
                                 return;
                             else
                                 reporting.Error('PTKDependencyList:DependencyMismatch', ['Dependency mismatch found for plugin ' dependency.PluginName '. You can fix this by clearing the cache for this datset.']);
                             end
                         end
                    end
                end
            end
            dependency_exists = false;
        end
        
    end
end