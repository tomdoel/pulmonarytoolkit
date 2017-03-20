classdef MimContextMapping < handle
    % MimContextMapping. A class for specifying the relationship between
    % contexts.
    %
    % This class is used by the Framework to store the relationship between
    % a context (the region in the image over which results are calculated),
    % and its context sets (the set of contexts of which it is a member), and
    % alo the hierarchy of contexts. For example, the LeftLung and RightLung
    % contexts are both in the context set SingleLung, and these are both
    % children of the LungROI context.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    
    properties
        Context % The context
        ContextSet % The context type (of type MimContextSet)
        TemplateGenerationFunctions % The name of a function from which this context can be found
        ContextTriggerPlugin % The name of a plugin which, when called, will trigger saving of a template
        Parent %
        Children
    end
    
    methods
        function obj = MimContextMapping(context_id, context_set, template_generation_function, context_trigger_plugin, parent_context_mapping)
            obj.Context = context_id;
            obj.ContextSet = context_set;
            obj.TemplateGenerationFunctions = template_generation_function;
            obj.ContextTriggerPlugin = context_trigger_plugin;
            obj.Parent = parent_context_mapping;
            obj.Children = {};
            
            % Add this context to the list of contexts for this context type
            obj.ContextSet.AddContext(obj);
            
            if ~isempty(parent_context_mapping)
                obj.Parent.AddChild(obj);
            end
        end
        
        function AddChild(obj, child)
            obj.Children{end + 1} = child;
        end
    end
    
end

