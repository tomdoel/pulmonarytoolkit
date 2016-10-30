classdef PTKContextDef < handle
    % PTKContextDef. Defines contexts for the Pulmonary Toolkit
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
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Contexts
        ContextSets
    end
    
    methods
        function obj = PTKContextDef
            obj.CreateContexts;
        end
        
        function context = GetContexts(obj)
            context = obj.Contexts;
        end
        
        function context_sets = GetContextSets(obj)
            context_sets = obj.ContextSets;
        end
        
        function context = GetDefaultContext(~)
            context = PTKContext.LungROI;
        end
        
        function context = GetDefaultContextSet(~)
            context = PTKContextSet.LungROI;
        end
        
        function context = GetExportContext(~)
            % Returns the preferred context used when exporting an image.
            % Typically this might be the same as the original context so
            % that data are exported and imported in the same context 
            context = PTKContext.OrignalImage;
        end
        
        function context = GetOriginalDataContext(~)
            % Returns the context of the data when it was loaded.
            % The purpose is to aid fetching a template image where the 
            % context is not important, for example if considering the
            % metadata. Using the original context prevents having to
            % create and fetch different templates
            context = PTKContext.OrignalImage;
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
                
                % If the plugin specifies a PTKContextSet of type
                % PTKContextSet.LungROI, then we choose to return a context
                % of PTKContext.LungROI
            elseif context == PTKContextSet.LungROI
                output_context = PTKContext.LungROI;
                
            % In all other cases we choose a default context of the lung ROI
            else
                output_context = PTKContext.LungROI;
            end
        end
        

        function context_labels = GetContextLabels(~)
            context_labels = [
                PTKContext.Lungs, PTKContext.RightLung, PTKContext.LeftLung, ...
                PTKContext.RightUpperLobe, PTKContext.RightMiddleLobe, PTKContext.RightLowerLobe, ...
                PTKContext.LeftUpperLobe, PTKContext.LeftLowerLobe, ...
                PTKContext.R_AP, PTKContext.R_P, PTKContext.R_AN, ...
                PTKContext.R_L, PTKContext.R_M, PTKContext.R_S, ...
                PTKContext.R_MB, PTKContext.R_AB, PTKContext.R_LB, ...
                PTKContext.R_PB, PTKContext.L_APP, PTKContext.L_APP2, ...
                PTKContext.L_AN, PTKContext.L_SL, PTKContext.L_IL, ...
                PTKContext.L_S, PTKContext.L_AMB, PTKContext.L_LB, PTKContext.L_PB];    
        end        
    end
    
    methods (Access = private)
        function CreateContexts(obj)
            % Create the hierarchy of context types
            obj.ContextSets = containers.Map;
            full_set =  MimContextSetMapping(PTKContextSet.OriginalImage, []);
            roi_set = MimContextSetMapping(PTKContextSet.LungROI, full_set);
            lungs_set = MimContextSetMapping(PTKContextSet.Lungs, roi_set);
            single_lung_set = MimContextSetMapping(PTKContextSet.SingleLung, lungs_set);
            lobe_set = MimContextSetMapping(PTKContextSet.Lobe, single_lung_set);
            segment_set = MimContextSetMapping(PTKContextSet.Segment, lobe_set);
            any_set = MimContextSetMapping(PTKContextSet.Any, []);
            obj.ContextSets(char(PTKContextSet.OriginalImage)) = full_set;
            obj.ContextSets(char(PTKContextSet.LungROI)) = roi_set;
            obj.ContextSets(char(PTKContextSet.Lungs)) = lungs_set;
            obj.ContextSets(char(PTKContextSet.SingleLung)) = single_lung_set;
            obj.ContextSets(char(PTKContextSet.Lobe)) = lobe_set;
            obj.ContextSets(char(PTKContextSet.Segment)) = segment_set;
            obj.ContextSets(char(PTKContextSet.Any)) = any_set;
            
            % Create the hierarchy of contexts
            obj.Contexts = containers.Map;
            full_context =  MimContextMapping(PTKContext.OriginalImage, full_set, @PTKCreateTemplateForOriginalImage, 'PTKOriginalImage', []);
            roi_context = MimContextMapping(PTKContext.LungROI, roi_set, @PTKCreateTemplateForLungROI, 'PTKLungROI', full_context);
            lungs_context = MimContextMapping(PTKContext.Lungs, lungs_set, @PTKCreateTemplateForLungs, 'PTKGetContextForLungs', roi_context);

            for context = [PTKContext.LeftLung, PTKContext.RightLung]
                context_mapping = MimContextMapping(context, single_lung_set, @PTKCreateTemplateForSingleLung, 'PTKGetContextForSingleLung', lungs_context);
                obj.Contexts(char(context)) = context_mapping;
            end

            % Add right lobes
            for context = [PTKContext.RightUpperLobe, PTKContext.RightMiddleLobe, PTKContext.RightLowerLobe]
                context_mapping = MimContextMapping(context, lobe_set, @PTKCreateTemplateForLobe, 'PTKGetContextForLobe', obj.Contexts(char(PTKContext.RightLung)));
                obj.Contexts(char(context)) = context_mapping;
            end

            % Add left lobes
            for context = [PTKContext.LeftUpperLobe, PTKContext.LeftLowerLobe]
                context_mapping = MimContextMapping(context, lobe_set, @PTKCreateTemplateForLobe, 'PTKGetContextForLobe', obj.Contexts(char(PTKContext.LeftLung)));
                obj.Contexts(char(context)) = context_mapping;
            end
            
            % Segments for upper right lobe
            for context = [PTKContext.R_AP, PTKContext.R_P, PTKContext.R_AN]
                context_mapping = MimContextMapping(context, segment_set, @PTKCreateTemplateForSegment, 'PTKGetContextForSegment', obj.Contexts(char(PTKContext.RightUpperLobe)));
                obj.Contexts(char(context)) = context_mapping;
            end
            
            % Segments for middle right lobe
            for context = [PTKContext.R_L, PTKContext.R_M]
                context_mapping = MimContextMapping(context, segment_set, @PTKCreateTemplateForSegment, 'PTKGetContextForSegment', obj.Contexts(char(PTKContext.RightMiddleLobe)));
                obj.Contexts(char(context)) = context_mapping;
            end
            
            % Segments for lower right lobe
            for context = [PTKContext.R_S, PTKContext.R_MB, PTKContext.R_AB, PTKContext.R_LB, PTKContext.R_PB]
                context_mapping = MimContextMapping(context, segment_set, @PTKCreateTemplateForSegment, 'PTKGetContextForSegment', obj.Contexts(char(PTKContext.RightLowerLobe)));
                obj.Contexts(char(context)) = context_mapping;
            end
            
            % Segments for upper left lobe
            for context = [PTKContext.L_APP, PTKContext.L_APP2, PTKContext.L_AN, PTKContext.L_SL, PTKContext.L_IL]
                context_mapping = MimContextMapping(context, segment_set, @PTKCreateTemplateForSegment, 'PTKGetContextForSegment', obj.Contexts(char(PTKContext.LeftUpperLobe)));
                obj.Contexts(char(context)) = context_mapping;
            end
            
            % Segments for lower left lobe
            for context = [PTKContext.L_S, PTKContext.L_AMB, PTKContext.L_LB, PTKContext.L_PB]
                context_mapping = MimContextMapping(context, segment_set, @PTKCreateTemplateForSegment, 'PTKGetContextForSegment', obj.Contexts(char(PTKContext.LeftLowerLobe)));
                obj.Contexts(char(context)) = context_mapping;
            end
        
            obj.Contexts(char(PTKContext.OriginalImage)) = full_context;
            obj.Contexts(char(PTKContext.LungROI)) = roi_context;
            obj.Contexts(char(PTKContext.Lungs)) = lungs_context;
        end        
    end
end