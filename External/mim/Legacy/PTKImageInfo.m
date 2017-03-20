classdef PTKImageInfo < MimImageInfo
    % PTKImageInfo. Legacy support class for backwards compatibility. Replaced by MimImageInfo
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        
    
    methods
        function obj = PTKImageInfo(varargin)
            obj = obj@MimImageInfo(varargin{:});
        end
    end
end

