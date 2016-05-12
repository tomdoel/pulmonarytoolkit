classdef CoreCompiledFileInfo < handle
    % CoreCompiledFileInfo. Structure for caching information about compiled files.
    %
    %     CoreCompiledFileInfo is used by CoreMex and its related files to manage
    %     dependencies on mex files. You typically create a map of
    %     CoreMexInfo objects, each of which defines a file to be
    %     compiled, and pass it into CoreMex. You can also use CoreCudaInfo
    %     for cuda files.
    %
    %     The basic rule you must follow is to increment the version number
    %     of your CoreMexInfo object whenever you change the corresponding
    %     mex file. This will force recompilation of any older versions.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    
    properties
        Name
        Extension
        Path
        CompilerOptions
        OtherCompilerFiles
        CurrentVersion
        
        LastSuccessfulCompiledVersion
        LastAttemptedCompiledVersion
        LastSuccessfulCompiler
        LastAttemptedCompiler
        LastCompileFailed
        LastAttemptedCompileDatenum
        
        NeedsRecompile
        StatusID
    end
    
    methods
        function obj = CoreCompiledFileInfo(current_version, filename, extension, file_path, compiler_options, other_files)
            if nargin > 0
                obj.Name = filename;
                obj.Extension = extension;
                obj.Path = file_path;
                obj.CompilerOptions = compiler_options;
                obj.OtherCompilerFiles = other_files;
                obj.CurrentVersion = current_version;
            end
        end
    end
    
end

