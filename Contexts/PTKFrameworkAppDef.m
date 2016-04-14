classdef PTKFrameworkAppDef < handle
    % PTKFrameworkAppDef. Defines application-dependent behaviour for the
    % Framework
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Config
        ContextDef
        Directories
    end
    
    methods
        function obj = PTKFrameworkAppDef
            obj.Config = MimConfig;
            obj.ContextDef = PTKContextDef;
            obj.Directories = MimDirectories(obj.Config);
        end
        
        function context_def = GetContextDef(obj)
            context_def = obj.ContextDef;
        end
        
        function output_directory = GetOutputDirectory(obj)
            output_directory = fullfile(PTKDirectories.GetSourceDirectory, 'bin');
        end
        
        function files_to_compile = GetFilesToCompile(obj, reporting)
            files_to_compile = PTKGetMexFilesToCompile(reporting);
        end

        function config = GetFrameworkConfig(obj)
            config = obj.Config;
        end
        
        function directories = GetFrameworkDirectories(obj)
            directories = obj.Directories;
        end
        
        function debug_mode = IsDebugMode(obj)
            debug_mode = PTKSoftwareInfo.DebugMode;
        end
    end
end