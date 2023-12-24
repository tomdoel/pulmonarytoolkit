classdef MimMemoryCacheItem < handle
    % Used to hold a cached value and metadata in the memory cache.
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %        
    
    properties (SetAccess = private)
        Value
        Info
    end

    methods
        
        function obj = MimMemoryCacheItem(value, info)
            obj.Value = value;
            obj.Info = info;
        end
    end
end