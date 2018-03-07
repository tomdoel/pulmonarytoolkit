classdef PTKPluginResultsInfo < MimPluginResultsInfo
    % PTKPluginResultsInfo. Legacy support class. Replaced by MimPluginResultsInfo.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    methods
        function obj = PTKPluginResultsInfo(varargin)
            obj = obj@MimPluginResultsInfo(varargin{:});
        end
    end
end

