classdef PTKClassFactory < handle
    % PTKClassFactory. Allows the PTK application to create PTK-specific subclasses
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods
        function results_info = CreatePluginResultsInfo(~, varargin)
            results_info = PTKPluginResultsInfo(varargin{:});
        end
        
        function results_info = CreateOutputInfo(~, varargin)
            results_info = PTKOutputInfo(varargin{:});
        end
        
        function results_info = CreateEmptyOutputInfo(~)
            results_info = PTKOutputInfo.empty;
        end
        
        function dataset_stack_item = CreateDatasetStackItem(~, varargin)
            dataset_stack_item = PTKDatasetStackItem(varargin{:});
        end
        
        function dataset_stack_item = CreateEmptyDatasetStackItem(~)
            dataset_stack_item = PTKDatasetStackItem.empty;
        end
    end
end