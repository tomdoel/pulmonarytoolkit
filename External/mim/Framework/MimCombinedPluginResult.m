classdef MimCombinedPluginResult < CoreBaseClass
    % MimCombinedPluginResult. Part of the internal framework of the TD MIM Toolkit.
    %
    %     This class encapsulates the output from fetching a plugin result
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    
    properties (Access = private)
        Result
        OutputImage
        PluginHasBeenRun
        CacheInfo
    end
    
    methods
        function obj = MimCombinedPluginResult(result, output_image, plugin_has_been_run, cache_info)
            obj.Result = result;
            obj.OutputImage = output_image;
            obj.CacheInfo = cache_info;
            obj.PluginHasBeenRun = plugin_has_been_run;
        end
        
        function result = GetResult(obj)
            result = obj.Result;
        end
        
        function output_image = GetOutputImage(obj)
            output_image = obj.OutputImage;
        end
        
        function cache_info = GetCacheInfo(obj)
            cache_info = obj.CacheInfo;
        end
        
        function has_been_run = GetPluginHasBeenRun(obj)
            has_been_run = obj.PluginHasBeenRun;
        end
    end
end 

