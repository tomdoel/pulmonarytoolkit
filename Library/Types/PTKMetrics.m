classdef PTKMetrics < dynamicprops
    % PTKMetrics. A structure for holding data analysis results
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
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
            obj.addprop(property_name);
            obj.(property_name) = value;
            obj.MetricNameMap(property_name) = user_visible_name;
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
end

