classdef PTKImageInfo < MimImageInfo
    % PTKImageInfo. Legacy support class for backwards compatibility. Replaced by MimImageInfo
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    methods
        function obj = PTKImageInfo(varargin)
            obj = obj@MimImageInfo(varargin{:});
        end
    end
end

