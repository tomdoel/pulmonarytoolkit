classdef MivContextDef < handle
    % MivContextDef. Defines contexts for MIV
    %
    %
    %     There are a number of contexts, which each represent particular
    %     regions of the lung. For example, the OriginalImage context is the
    %     entire image, whereas the LungROI is the parrallipiped region
    %     containing the lungs and airways. The LeftLung and RightLung comprise
    %     just the voumes of the left and right lung respectively.
    %
    %     Context sets describe a collection of related contexts. For example,
    %     the SingleLung context set contains LeftLung and RightLung.
    %
    %     Each plugin specifies its context set, which is the domain of the
    %     results produced by the plugin. Some plugins operate over the whole
    %     LungROI region, while some operate on individual lungs.
    %
    %     This class manages the situations where a result is requested for a
    %     particualar context (e.g. LungROI) but the plugin defines a different
    %     context set (e.g. SingleLung). The LungROI can be built from the two
    %     contexts in the SingleLung set. Therefore in this case, the plugin is run twice,
    %     once for the left and once for the right lung. Then the resutls are
    %     combined to produce the result for the LungROI context.
    %
    %     Thie class defines this heirarchy of contexts and context sets. In
    %     this way plugins can operate on whichever context is appropriate,
    %     while results can be requested for any context, and the conversions
    %     are handled automatically.
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        Contexts
        ContextSets
    end
    
    methods
        function obj = MivContextDef
            obj.CreateContexts;
        end
        
        function context = GetContexts(obj)
            context = obj.Contexts;
        end
        
        function context_sets = GetContextSets(obj)
            context_sets = obj.ContextSets;
        end
        
        function context = GetDefaultContext(~)
            context = PTKContext.OriginalImage;
        end
        
        function context = GetDefaultContextSet(~)
            context = PTKContextSet.OriginalImage;
        end
        
        function matches = ContextSetMatches(~, plugin_context_set, requested_context_set)
            % Returns true if the plugin_context_set can be used to
            % generate the context_set without conversion
            
            matches = (plugin_context_set == requested_context_set) || (plugin_context_set == PTKContextSet.Any);
        end
        
        function output_context = ChooseOutputContext(~, context)
            % If a specific context has been specified in the plugin, we use
            % this (note this is not normally the case, as plugins usually
            % specify a PTKContextSet rather than a PTKContext)
            if isa(context, 'PTKContext')
                output_context = plugin_info.Context;
                
                % If the plugin specifies a PTKContextSet of type
                % PTKContextSet.OriginalImage, then we choose to return a context
                % of PTKContext.OriginalImage
            elseif context == PTKContextSet.OriginalImage
                output_context = PTKContext.OriginalImage;
                
            % In all other cases we choose a default context of the lung ROI
            else
                output_context = PTKContext.OriginalImage;
            end
        end
        
    end
    
    methods (Access = private)
        function CreateContexts(obj)
            % Create the hierarchy of context types
            obj.ContextSets = containers.Map();
            full_set =  MimContextSetMapping(PTKContextSet.OriginalImage, []);
            any_set = MimContextSetMapping(PTKContextSet.Any, []);
            obj.ContextSets(char(PTKContextSet.OriginalImage)) = full_set;
            obj.ContextSets(char(PTKContextSet.Any)) = any_set;
            
            % Create the hierarchy of contexts
            obj.Contexts = containers.Map();
            full_context =  MimContextMapping(PTKContext.OriginalImage, full_set, 'PTKGetContextForOriginalImage', 'PTKOriginalImage', []);

            obj.Contexts(char(PTKContext.OriginalImage)) = full_context;
        end        
    end
end