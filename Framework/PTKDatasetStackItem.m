classdef PTKDatasetStackItem < handle
    % PTKDatasetStackItem. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Used to store the dependency information of a plugin as it is being
    %     build up during execution. PTKDatasetStackItem are created 
    %     temporarily by the class PTKDatasetStack and used to build up the
    %     dependency list. See PTKDatasetStack for more information.
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
        IsEdited
        Schema                 % The disk cache version
    end
    
    properties (SetAccess = private, Transient = true)
        ExecutionTimer         % Times the execution time for this plugin
    end
    
    methods
        function obj = PTKDatasetStackItem(instance_id, dependency_list, ignore_dependency_checks, start_timer, reporting)
            if ~isa(instance_id, 'PTKDependency')
                reporting.Error('PTKDatasetStackItem:BadInstanceID', 'instance_id must be a PTKDependency object');
            end
            
            if ~isa(dependency_list, 'PTKDependencyList')
                reporting.Error('PTKDatasetStackItem:BadDependencyList', 'dependency_list must be a PTKDependencyList object');
            end
                        
            obj.InstanceIdentifier = instance_id;
            obj.DependencyList = dependency_list;
            obj.IgnoreDependencyChecks = ignore_dependency_checks;
            obj.Schema = PTKSoftwareInfo.DiskCacheSchema;
            obj.IsEdited = false;
            
            if start_timer
                obj.ExecutionTimer = PTKTimer(reporting);
                obj.ExecutionTimer.Start;
            end
        end
        
        function AddDependencies(obj, dependencies, reporting)
            % Adds more plugin result which this particular plugin result depends on.
        
            obj.DependencyList.AddDependenciesList(dependencies, reporting);
        end
        
        function StopAndDeleteTimer(obj)
            if ~isempty(obj.ExecutionTimer)
                obj.ExecutionTimer.Stop;
                obj.InstanceIdentifier.Attributes.ExecutionTime = obj.ExecutionTimer.TotalElapsedTime;
                obj.InstanceIdentifier.Attributes.SelfTime = obj.ExecutionTimer.SelfTime;
                obj.ExecutionTimer = [];
            end
        end
        
        function MarkEdited(obj)
            obj.IsEdited = true;
        end
    end
    
end

