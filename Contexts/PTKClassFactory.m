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
        function results_info = CreatePluginResultsInfo(~)
            results_info = PTKPluginResultsInfo;
        end
    end
end