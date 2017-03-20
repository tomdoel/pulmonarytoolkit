classdef MimClassFactory < handle
    % MimClassFactory. Allows MIM applications to create application-specific subclasses
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
            results_info = MimPluginResultsInfo(varargin{:});
        end
        
        function results_info = CreateOutputInfo(~, varargin)
            results_info = MimOutputInfo(varargin{:});
        end
        
        function results_info = CreateEmptyOutputInfo(~)
            results_info = MimOutputInfo.empty;
        end
        
        function dataset_stack_item = CreateDatasetStackItem(~, varargin)
            dataset_stack_item = MimDatasetStackItem(varargin{:});
        end
        
        function dataset_stack_item = CreateEmptyDatasetStackItem(~)
            dataset_stack_item = MimDatasetStackItem.empty;
        end
    end
end