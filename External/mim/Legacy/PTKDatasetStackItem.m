classdef PTKDatasetStackItem < MimDatasetStackItem
    % Legacy support class for backwards compatibility. Replaced by MimDatasetStackItem
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    methods
        function obj = PTKDatasetStackItem(varargin)
            obj = obj@MimDatasetStackItem(varargin{:});
        end
    end
end
