classdef PTKMexInfo < handle
    % PTKMexInfo. Structure for caching information about compiled mex files.
    %
    %     PTKCompileMexFiles is an internal part of the Pulmonary Toolkit
    %     Framework and should not be called by your own code.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        
        NeedsRecompile
        StatusID
    end
    
    methods
        function obj = PTKMexInfo(current_version, filename, extension, file_path, compiler_options, other_files)
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

