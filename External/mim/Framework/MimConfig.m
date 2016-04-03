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

        DiskCacheFolderName = 'ResultsCache' % Name for folder containing cache of plugin results
        FrameworkDatasetCacheFolderName = 'FrameworkDatasetCache' % Name for folder containing framework cache files
        EditedResultsDirectoryName = 'EditedResults' % Name for folder used to store user corrections to plugin results
        ManualSegmentationsDirectoryName = 'ManualSegmentations' % Name for folder used to store manual segmentations
        MarkersDirectoryName = 'Markers' % Name for folder used to store user-placed markers

        CachedPluginInfoFileName = 'CachedPluginInfo' % Filename for internal cache of plugin infos
        ImageInfoCacheName = 'ImageInfo' % Filename for per-dataset cache of filenames and dataset information
        MexCacheFileName = 'MexCache.xml' % Filename for cache of information about compiled mex files
        ImageDatabaseFileName = 'ImageDatabase.mat'
    end
    
end

