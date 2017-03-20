classdef MimPipelines < CoreBaseClass
    % MimPipelines. Part of the internal framework of the TD MIM Toolkit.
    %
    %     This class is used to execute Plugins automatically, triggered by
    %     the completion of other Plugins. This automatic triggering is
    %     called a Pipeline. A Pipeline might be used to perform some
    %     automatic operation.
    
    %     Pipelines can also be used to more efficiently
    %     generate results which depend on some other result. For example,
    %     suppose plugins A and B depends on plugin C, but suppose you do
    %     not wish to cache the results of C permanently. Calling A will
    %     result in a call to C; it may be efficient to also compute B
    %     while the result of C is available in memory. This can be accomplished by
    %     creating a pipeline such that B is called automatically when C is
    %     run. For this to work, the result of C should have its memory
    %     cache policy set to at least temporary.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        % A map of all valid contexts to the function required to generate the
        % context from the result of the plugin
        PipelinePlugins
        
        % Callback for running the pipeline plugins
        DatasetResults
    end
    
    methods
        function obj = MimPipelines(dataset_results, context_def)
            obj.DatasetResults = dataset_results;
            
            % Create empty maps. Maps must be initialised in the constructor,
            % not as default property values. Initialising as default property
            % values results in every instance of this claas sharing the same
            % map instance
            obj.PipelinePlugins = containers.Map;
        end
        
        function AddPipeline(obj, trigger_plugin, trigger_context, pipeline_plugin)
            % Add a new pipeline. The plugin defined by pipeline_plugin
            % will be called after the plugin trigger_plugin is called
            % successfully
            
            trigger_key = [trigger_plugin '.' char(trigger_context)];
            if ~obj.PipelinePlugins.isKey(trigger_key)
                obj.PipelinePlugins(trigger_key) = {};
            end
            obj.PipelinePlugins(trigger_key) = [obj.PipelinePlugins(trigger_key), pipeline_plugin];
        end
        
        function RunPipelines(obj, trigger_plugin, trigger_context, result_may_have_changed, dataset_stack, dataset_uid, reporting)
            % Run any required pipelines associated with this plugin and context
            
            trigger_key = [trigger_plugin '.' char(trigger_context)];
            if obj.PipelinePlugins.isKey(trigger_key)
                pipelines = obj.PipelinePlugins(trigger_key);
                for pipeline = pipelines
                    pipeline_plugin = pipeline{1};
                    % Only run the pipeline if a value does not already
                    % exist, or if the source plugin has been run which
                    % indicates the value will no longer be valid
                    if result_may_have_changed || obj.DatasetResults.ResultExistsForSpecificContext(pipeline_plugin, trigger_context, reporting);

                        % Trigger pipeline if it is not alreadu being run
                        % (stops recursion). The plugin result which triggered the pipeline should generally be cached
                        if ~dataset_stack.PluginAlreadyExistsInStack(pipeline_plugin, trigger_context, dataset_uid)
                            obj.DatasetResults.GetResult(pipeline_plugin, dataset_stack, trigger_context, reporting);
                        end                            
                    end                    
                end
            end
            
        end        
    end
end