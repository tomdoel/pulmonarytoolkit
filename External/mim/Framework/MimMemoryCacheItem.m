classdef MimMemoryCacheItem < handle
    % MimMemoryCacheItem. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Used to hold a cached value and metadata in the memory cache.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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