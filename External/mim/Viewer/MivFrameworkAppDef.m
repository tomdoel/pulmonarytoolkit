classdef MivFrameworkAppDef < handle
    % MivFrameworkAppDef. Defines application-dependent behaviour for the
    % Framework
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        Config
        ContextDef
        Directories
        ClassFactory
    end
    
    methods
        function obj = MivFrameworkAppDef
            obj.Config = MimConfig();
            obj.ContextDef = MivContextDef();
            obj.Directories = MimDirectories(obj.GetApplicationParentDirectory, obj.Config);
            obj.ClassFactory = MimClassFactory();
        end
        
        function context_def = GetContextDef(obj)
            context_def = obj.ContextDef;
        end
        
        function class_factory = GetClassFactory(obj)
            class_factory = obj.ClassFactory;
        end
        
        function parent_directory = GetApplicationParentDirectory(obj)
            parent_directory = CoreDiskUtilities.GetUserDirectory();
        end
        
        function bin_directory = GetBinDirectory(obj)
            bin_directory = fullfile(CoreDiskUtilities.GetUserDirectory(), 'mim', 'bin');
        end
        
        function files_to_compile = GetFilesToCompile(obj, reporting)
            files_to_compile = MivGetMexFilesToCompile(reporting);
        end

        function config = GetFrameworkConfig(obj)
            config = obj.Config;
        end
        
        function directories = GetFrameworkDirectories(obj)
            directories = obj.Directories;
        end
        
        function debug_mode = IsDebugMode(obj)
            debug_mode = false;
        end
        
        function time_functions = TimeFunctions(obj)
            time_functions = obj.Config.TimeFunctions;
        end
        
        function NewDatasetLoaded(obj, dataset_uid, dataset, reporting)
        end
        
        function plugins_path = GetUserPath(~)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', 'User');
        end
    end
end