classdef PTKSoftwareInfo < handle
    % PTKSoftwareInfo. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Provides information about the software including folder names and 
    %     DICOM metadata written to exported files.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Constant)
        
        % Version numbers
        Version = '0.3'
        DicomVersion = '0.1'
        DiskCacheSchema = '0.1'
        XMLVersion = '0.1'
        PTKVersion = '2'
        MatlabMinimumMajorVersion = 7
        MatlabMinimumMinorVersion = 11
        MatlabAdvisedMajorVersion = 7
        MatlabAdvisedMinorVersion = 14

        % Name of application
        Name = 'Pulmonary Toolkit'
        DicomName = 'TD Pulmonary Toolkit'
        DicomManufacturer = 'www tomdoel com'
        DicomStudyDescription = 'TD Pulmonary Toolkit exported images'
        WebsiteUrl = 'http://code.google.com/p/pulmonarytoolkit'

        % Appearance
        BackgroundColour = [0, 0.129, 0.278]
        GraphFont = 'Helvetica'
        GuiFont = 'Helvetica'
        DefaultCategoryName = 'Uncategorised'
        
        % Directories
        DiskCacheFolderName = 'ResultsCache'
        OutputDirectoryName = 'Output'
        EditedResultsDirectoryName = 'EditedResults'
        ApplicationSettingsFolderName = 'TDPulmonaryToolkit'
        PluginDirectoryName = 'Plugins'
        GuiPluginDirectoryName = fullfile('Gui', 'GuiPlugins')
        MexSourceDirectory = fullfile('Library', 'mex')
        UserDirectoryName = 'User'
        TestSourceDirectory = 'Test'

        % Filenames
        LogFileName = 'log.txt'
        CachedPluginInfoFileName = 'CachedPluginInfo'
        PreviewImageFileName = 'PreviewImages'
        SettingsFileName = 'PTKSettings.mat'
        FrameworkCacheFileName = 'PTKFrameworkCache.mat'
        ImageDatabaseFileName = 'PTKImageDatabase.mat'
        MakerPointsCacheName = 'MarkerPoints'
        ImageInfoCacheName = 'ImageInfo'
        SchemaCacheName = 'Schema'
        ImageTemplatesCacheName = 'ImageTemplates'
        SplashScreenImageFile = 'PTKLogo.jpg'

        
        % Debugging and optional arguments
        DebugMode = false
        GraphicalDebugMode = false
        TimeFunctions = true
        FastMode = false
        DemoMode = false % If true, user plugins will be ignored
        WriteVerboseEntriesToLogFile = false
        RecycleWhenDeletingCacheFiles = false
        
        % Do not change this
        CancelErrorId = 'PTKMain:UserCancel'
        FileMissingErrorId = 'PTKMain:FileMissing'
    end

    methods (Static)
        function [major_version, minor_version] = GetMatlabVersion
            [matlab_version, ~] = version;
            version_matrix = sscanf(matlab_version, '%d.%d.%d.%d');
            major_version = version_matrix(1);
            minor_version = version_matrix(2);
        end
        
        function is_cancel_id = IsErrorCancel(error_id)
            is_cancel_id = strcmp(error_id, PTKSoftwareInfo.CancelErrorId);
        end
        
        function is_error_missing_id = IsErrorFileMissing(error_id)
            is_error_missing_id = strcmp(error_id, PTKSoftwareInfo.FileMissingErrorId);
        end
    end
end

