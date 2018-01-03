classdef PTKMetrics < dynamicprops
    % PTKMetrics. A structure for holding data analysis results
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    properties (SetAccess = private)
        MetricNameMap
    end
    
    methods
        function obj = PTKMetrics
            obj.MetricNameMap = containers.Map;
        end
        
        function AddMetric(obj, property_name, value, user_visible_name)
            valid_property_name = CoreTextUtilities.CreateValidFieldName(property_name);
            obj.addprop(valid_property_name);
            obj.(valid_property_name) = value;
            obj.MetricNameMap(valid_property_name) = user_visible_name;
        end
        
        function property_list = GetListOfMetrics(obj)
            property_list = properties(obj);
            property_list = setdiff(property_list, 'MetricNameMap');
        end
        
        function Merge(obj, metrics, reporting, prefix, user_visible_prefix)
            if nargin < 4
                prefix = [];
                user_visible_prefix = [];
            end
            if ~isa(metrics, 'PTKMetrics')
                reporting.Error('PTKMetrics:NotAMetricsClass', 'The argument passed to Merge() was not of type PTKMetrics');
            end

            metric_list = metrics.GetListOfMetrics;
            for i = 1 : length(metric_list)
                metric = metric_list{i};
                obj.AddMetric([prefix, metric], metrics.(metric), [user_visible_prefix, metrics.MetricNameMap(metric)]);
            end
        end
    end
    
    methods (Static)
        function results = MergeResults(results_1, results_2)
            if isempty(results_2)
                results = results_1;
            else
                metric_names = unique([fieldnames(results_1), fieldnames(results_2)]);
                results = [];
                for metric_cell = metric_names'
                    metric_name = metric_cell{1};
                    if isfield(results_1, metric_name)
                        results.(metric_name) = results_1.(metric_name);
                    end
                    if isfield(results, metric_name)
                        if isfield(results_2, metric_name)
                            results.(metric_name).Merge(results_2.(metric_name))
                        else
                            results.(metric_name) = results_2.(metric_name);
                        end
                    end
                end
            end
        end 
    end
end

