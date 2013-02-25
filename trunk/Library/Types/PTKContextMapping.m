classdef PTKContextMapping < handle
    % PTKContextMapping. A class for specifying the relationship between
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties
        Context % The context (of type PTKContext)
        ContextSet % The context type (of type PTKContextSet)
        TemplateImagePluginName % The name of a plugin from which this context can be found
        Parent %
        Children
    end
    
    methods
        function obj = PTKContextMapping(context_id, context_set, template_plugin_name, parent_context_mapping)
            obj.Context = context_id;
            obj.ContextSet = context_set;
            obj.TemplateImagePluginName = template_plugin_name;
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

