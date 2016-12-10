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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Constant)
        
        % Version numbers
        Version = '0.6.3'
        PTKVersion = '2'
        MatlabMinimumMajorVersion = 7
        MatlabMinimumMinorVersion = 12
        MatlabAdvisedMajorVersion = 7
        MatlabAdvisedMinorVersion = 14

        % Name of application
        WebsiteUrl = 'https://github.com/tomdoel/pulmonarytoolkit'

        % Appearance
        GraphFont = 'Helvetica'
        GuiFont = 'Helvetica' 
        DefaultCategoryName = 'Uncategorised'
        PluginDefaultMode = 'Plugins'
        DefaultModeOnNewDataset = 'Segment'
        Colormap = CoreSystemUtilities.BackwardsCompatibilityColormap;
        
        % If this parameter to true, then the patient browser will group together
        % datasets with the same patient name, even if the patient ID is different
        GroupPatientsWithSameName = true
        
        % Directories
        GuiToolDirectoryName = fullfile('Gui', 'Toolbar')
        MexSourceDirectory = fullfile('Library', 'mex')
        TestSourceDirectory = 'Test'
        
        % Filenames
        LogFileName = 'log.txt'
        SettingsFileName = 'PTKSettings.mat'
        MakerPointsCacheName = 'MarkerPoints' % Default marker points name

        % Debugging and optional arguments
        DebugMode = false
        GraphicalDebugMode = false
        FastMode = false
        DemoMode = false % If true, user plugins will be ignored
        WriteVerboseEntriesToLogFile = false
        
        % If true, the user will be prompted before marker changes are saved
        ConfirmBeforeSavingMarkers = false
        
        % Registration parameters
        ShowRegistrationConvergence = false
        RegistrationBodyForceTol = 0.01
        RegistrationBodyForceDiffTol = 0.001
    end
end

