classdef MimConfig < handle
    % MimConfig. Framework configuration settings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        SchemaCacheName = 'Schema' % Name of the scheme versioning file in each disk cache directory
        RecycleWhenDeletingCacheFiles = false % Whether deleted cache files go to the recycle bin
        Compression = 'deflate' % Compression to use when saving cache images

        CachedPluginInfoFileName = 'CachedPluginInfo' % Filename for internal cache of plugin infos
    end
    
end

