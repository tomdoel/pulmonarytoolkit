classdef MimConfig < handle
    % Framework configuration settings
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
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
        OutputDirectoryName = 'Output'

        ApplicationSettingsFolderName = 'TDPulmonaryToolkit' % Framework base folder for settings, logs, cache
        CachedPluginInfoFileName = 'CachedPluginInfo' % Filename for internal cache of plugin infos
        ImageInfoCacheName = 'ImageInfo' % Filename for per-dataset cache of filenames and dataset information
        MexCacheFileName = 'MexCache.xml' % Filename for cache of information about compiled mex files
        ImageDatabaseFileName = 'ImageDatabase.mat' % Filename for cache of image database
        LinkingCacheFileName = 'PTKLinkingCache.xml' % Filename for cache of linked datasets
        OutputFolderCacheName = 'OutputFolder' % Filename for cache of output results
        PreviewImageFileName = 'PreviewImages' % Filename for cache of preview images
        ImageTemplatesCacheName = 'ImageTemplates' % Filename for cache of image context templates
        
        TimeFunctions = true        
    end
end

