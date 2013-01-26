classdef TDSoftwareInfo < handle
    % TDSoftwareInfo. Part of the internal framework of the Pulmonary Toolkit.
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
        Version = '0.1'
        DicomVersion = '0.1'
        Name = 'Pulmonary Toolkit'
        DicomName = 'TD Pulmonary Toolkit'
        DicomManufacturer = 'www tomdoel com'
        DicomStudyDescription = 'TD Pulmonary Toolkit exported images'
        DiskCacheFolderName = 'ResultsCache'
        ApplicationSettingsFolderName = 'TDPulmonaryToolkit'
        DiskCacheSchema = '0.1'
        LogFileName = 'log.txt'
        PluginDirectoryName = 'Plugins'
        GuiPluginDirectoryName = fullfile('Gui', 'GuiPlugins')
        PreviewImageFileName = 'PreviewImages'
        PTKVersion = '1'
        CachedPluginInfoFileName = 'CachedPluginInfo'
        SettingsFileName = 'PTKSettings.mat'
        FrameworkCacheFileName = 'TDFrameworkCache.mat'
        MakerPointsCacheName = 'MarkerPoints'
        ImageInfoCacheName = 'ImageInfo'
        SchemaCacheName = 'Schema'
        ImageTemplatesCacheName = 'ImageTemplates'
        MexSourceDirectory = fullfile('Library', 'mex')
        UserDirectoryName = 'User'
        ResultsDirectoryName = 'Results'
        WebsiteUrl = 'http://code.google.com/p/pulmonarytoolkit'
        MatlabMinimumMajorVersion = 7
        MatlabMinimumMinorVersion = 11
        MatlabAdvisedMajorVersion = 7
        MatlabAdvisedMinorVersion = 14
        DebugMode = false
        GraphicalDebugMode = false
        BackgroundColour = [0, 0.129, 0.278]
        CancelErrorId = 'TDPTK:UserCancel'
        TimeFunctions = true;
        FastMode = false;
        GraphFont = 'Helvetica'
        GuiFont = 'Helvetica'
        SplashScreenImageFile = 'PTKLogo.jpg'
    end

    methods (Static)
        function application_directory = GetApplicationDirectoryAndCreateIfNecessary
            if ~isempty(PTKConfig.CacheFolder)
                home_directory = PTKConfig.CacheFolder;
            else
                home_directory = TDDiskUtilities.GetUserDirectory;
            end
            application_directory = TDSoftwareInfo.ApplicationSettingsFolderName;
            application_directory = fullfile(home_directory, application_directory);  
            if ~exist(application_directory, 'dir')
                mkdir(application_directory);
            end
        end

        function [major_version, minor_version] = GetMatlabVersion
            [matlab_version, ~] = version;
            version_matrix = sscanf(matlab_version, '%d.%d.%d.%d');
            major_version = version_matrix(1);
            minor_version = version_matrix(2);
        end
        
        function source_directory = GetSourceDirectory
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            source_directory = fullfile(path_root, '..');
        end
        
        function is_cancel_id = IsErrorCancel(error_id)
            is_cancel_id = strcmp(error_id, TDSoftwareInfo.CancelErrorId);
        end
    end
end

