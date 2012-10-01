classdef TDDatasetStackItem < handle
    % TDDatasetStackItem. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Used to store the dependency information of a plugin as it is being
    %     build up during execution. TDDatasetStackItem are created 
    %     temporarily by the class TDDatasetStack and used to build up the
    %     dependency list. See TDDatasetStack for more information.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (SetAccess = private)
        InstanceIdentifier     % A unique identifier for this plugin result
        IgnoreDependencyChecks % Certain types of plugin do not cached their results and so are exempt from dependency checking
        DependencyList         % Current list of plugin results this plugin depends on
        Schema                 % The disk cache version
    end
    
    methods
        function obj = TDDatasetStackItem(instance_id, dependency_list, ignore_dependency_checks, reporting)
            if ~isa(instance_id, 'TDDependency')
                reporting.Error('TDDatasetStackItem:BadInstanceID', 'instance_id must be a TDDependency object');
            end
            
            if ~isa(dependency_list, 'TDDependencyList')
                reporting.Error('TDDatasetStackItem:BadDependencyList', 'dependency_list must be a TDDependencyList object');
            end
                        
            obj.InstanceIdentifier = instance_id;
            obj.DependencyList = dependency_list;
            obj.IgnoreDependencyChecks = ignore_dependency_checks;
            obj.Schema = TDSoftwareInfo.DiskCacheSchema;
        end
        
        % Adds more plugin result which this particular plugin result depends
        % on.
        function AddDependencies(obj, dependencies, reporting)
            obj.DependencyList.AddDependenciesList(dependencies, reporting);
        end
    end
    
end

