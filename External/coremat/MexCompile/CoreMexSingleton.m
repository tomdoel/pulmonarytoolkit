classdef (Sealed) CoreMexSingleton < handle
    % A singleton used for storing mex compilation information
    %
    % CoreMexSingleton is a singleton. It cannot be created using the
    % constructor; instead call CoreMexSingleton.GetMexSingleton;
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        MexCache         % Information about mex files which is cached on disk
    end
        
    methods (Static)
        function mex_singleton = GetMexSingleton(fileName, reporting)
            persistent MexSingleton
            if isempty(MexSingleton) || ~isvalid(MexSingleton)
                MexSingleton = CoreMexSingleton(fileName, reporting);
            end
            mex_singleton = MexSingleton;
        end
    end
    
    methods
        function CompileMexFileIfRequired(obj, filesToCompile, compileDirectory, reporting)
            % Recompiles mex files if they have changed
            
            CoreCompileMexFiles(obj.MexCache, compileDirectory, filesToCompile, false, ' Run CoreMexSingleton.Recompile() to force recompilation.', reporting);
        end
        
        function RecompileMexFiles(obj, filesToCompile, compileDirectory, reporting)
            % Forces recompilation of mex files
            
            CoreCompileMexFiles(obj.MexCache, compileDirectory, filesToCompile, true, ' Run CoreMexSingleton.Recompile() to force recompilation.', reporting);
        end
    end
    
    methods (Access = private)
        function obj = CoreMexSingleton(fileName, reporting)
            obj.MexCache = CoreMexCache.LoadCache(fileName, reporting);
        end
    end    
end
