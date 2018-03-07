classdef MimMemoryCacheItem < handle
    % MimMemoryCacheItem. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     Used to hold a cached value and metadata in the memory cache.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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