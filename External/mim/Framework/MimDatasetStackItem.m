classdef MimDatasetStackItem < handle
    % MimDatasetStackItem. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Used to store the dependency information of a plugin as it is being
    %     build up during execution. MimDatasetStackItem are created 
    %     temporarily by the class MimDatasetStack and used to build up the
    %     dependency list. See MimDatasetStack for more information.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
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
    
    properties (Access = private, Transient)
        DiskCacheSchema = '0.1'
    end
    
    methods
        function obj = MimDatasetStackItem(instance_id, dependency_list, ignore_dependency_checks, start_timer, reporting)
            if nargin > 0
                if ~isa(instance_id, 'MimDependency')
                    reporting.Error('MimDatasetStackItem:BadInstanceID', 'instance_id must be a MimDependency object');
                end

                if ~isa(dependency_list, 'MimDependencyList')
                    reporting.Error('MimDatasetStackItem:BadDependencyList', 'dependency_list must be a MimDependencyList object');
                end

                obj.InstanceIdentifier = instance_id;
                obj.DependencyList = dependency_list;
                obj.IgnoreDependencyChecks = ignore_dependency_checks;
                obj.Schema = obj.DiskCacheSchema;
                obj.IsEdited = false;

                if start_timer
                    obj.ExecutionTimer = MimTimer(reporting);
                    obj.ExecutionTimer.Start;
                end
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
    
    methods (Static)
        function obj = loadobj(a)
            % This method is called when the object is loaded from disk.
            
            if isa(a, 'MimDatasetStackItem')
                obj = a;
            else
                % In the case of a load error, loadobj() gives a struct
                obj = MimDatasetStackItem;
                for field = fieldnames(a)'
                    if isprop(obj, field{1})
                        mp = findprop(obj, (field{1}));
                        if (~mp.Constant) && (~mp.Dependent) && (~mp.Abstract) 
                            obj.(field{1}) = a.(field{1});
                        end
                    end
                end
            end
            
        end
    end
end

