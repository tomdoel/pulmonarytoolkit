classdef PTKCombinedPluginResult < CoreBaseClass
    % PTKCombinedPluginResult. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     This class encapsulates the output from fetching a plugin result
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties (Access = private)
        Result
        OutputImage
        PluginHasBeenRun
        CacheInfo
    end
    
    methods
        function obj = PTKCombinedPluginResult(result, output_image, plugin_has_been_run, cache_info)
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

