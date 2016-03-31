classdef PTKPluginResultsInfo < handle
    % PTKPluginResultsInfo. Legacy support class. Replaced by MimPluginResultsInfo.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Provides metadata about plugin results, concerning the list of 
    %     dependencies used in generating each result for this dataset.
    %     This data is stored alongside plugin results in the disk cache, and is
    %     used to determine if a particular result is still valid. A result is
    %     still valid if the uid of each dependency in the dependency list 
    %     matches the uid of the current result for the matching plugin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        ResultsInfo
    end
    
    methods
        function obj = PTKPluginResultsInfo
            obj.ResultsInfo = containers.Map;
        end
        
        function mim_info = ConvertToMimInfo(obj)
            % Converts this object to MimPluginResultsInfo
            mim_info = MimPluginResultsInfo(obj.ResultsInfo);
        end
    end
end

