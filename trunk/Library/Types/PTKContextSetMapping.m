classdef PTKContextSetMapping < handle
    % PTKContextSetMapping. A class for specifying the relationship between
    % context sets.
    %
    % This class is used by the Framework to store the relationship between
    % a context set (a set of related contexts) and its contexts; and 
    % also the hierarchy of contexts. For example, the LeftLung and RightLung
    % contexts are both in the context set SingleLung. The SingleLung set is a 
    % child of the LungROI context set.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties
        ContextSet  % The context set enum (of type PTKContextSet)
        
        ContextList % The set of PTKContextMappings corresponding to contexts of this type 
        
        Parent      % Parent type (of type PTKContextSetMapping)
        Children    % Child type (of type PTKContextSetMapping)
    end
    
    methods
        function obj = PTKContextSetMapping(context_set_id, parent_context_set_mapping)
            obj.ContextSet = context_set_id;
            obj.Parent = parent_context_set_mapping;
            obj.ContextList = {};
            obj.Children = {};
            
            if ~isempty(parent_context_set_mapping)
                obj.Parent.AddChild(obj);
            end
        end
        
        function AddChild(obj, child)
            obj.Children{end + 1} = child;
        end
        
        function AddContext(obj, context)
            obj.ContextList{end + 1} = context;
        end

        % Determines if the specified context set is higher in the hierarchy
        % than this set
        function is_higher = IsOtherContextSetHigher(obj, other_context_set)
            next_set = obj.Parent;
            while ~isempty(next_set)
                if next_set == other_context_set
                    is_higher = true;
                    return;
                end
                next_set = next_set.Parent;
            end
            is_higher = false;
        end
    end
    
end

