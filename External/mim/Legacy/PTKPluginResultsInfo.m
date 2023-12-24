classdef PTKPluginResultsInfo < MimPluginResultsInfo
    % Legacy support class. Replaced by MimPluginResultsInfo.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    methods
        function obj = PTKPluginResultsInfo(varargin)
            obj = obj@MimPluginResultsInfo(varargin{:});
        end
    end
end

