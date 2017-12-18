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
        Version = '0.7.9'
        DicomVersion = '0.1'
        DiskCacheSchema = '0.1'
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

        % Directories
        ScriptsDirectoryName = 'Scripts'
        GuiToolDirectoryName = fullfile('Gui', 'Toolbar')
        MexSourceDirectory = fullfile('Library', 'mex')
        TestSourceDirectory = 'Test'
        
        % Debugging and optional arguments
        DebugMode = false
        GraphicalDebugMode = false
        FastMode = false
        DemoMode = false % If true, user plugins will be ignored
        
        % Registration parameters
        ShowRegistrationConvergence = false
        RegistrationBodyForceTol = 0.01
        RegistrationBodyForceDiffTol = 0.001
    end
end

