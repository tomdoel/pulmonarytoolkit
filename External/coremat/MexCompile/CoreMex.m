classdef CoreMex < CoreBaseClass
    % CoreMex Class for auto-compiling mex files
    %
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (SetAccess = private)
        CompileBinDirectory
        FileList
        MexSingleton
        Reporting          % Object for error and progress reporting
    end

    methods
        
        function obj = CoreMex(mexFileList, reporting)
            % Takes in an array of  of mex files and compiles any that are out of
            % date
            
            if nargin < 2
                reporting = CoreReportingDefault;
            end
            
            mexCacheFilename = fullfile(CoreDiskUtilities.GetUserDirectory, 'depmat', 'MexCache.xml');
            
            obj.Reporting = reporting;
            obj.MexSingleton = CoreMexSingleton.GetMexSingleton(mexCacheFilename, obj.Reporting);
            obj.CompileBinDirectory = fullfile(CoreDiskUtilities.GetUserDirectory, 'depmat', 'mex_bin');
            CoreDiskUtilities.CreateDirectoryIfNecessary(obj.CompileBinDirectory);
            addpath(obj.CompileBinDirectory);
            obj.FileList = mexFileList;
            obj.MexSingleton.CompileMexFileIfRequired(obj.FileList, obj.CompileBinDirectory, obj.Reporting);
        end
        
        function Recompile(obj)
            % Forces recompilation of all mex files
            
            obj.MexSingleton.Recompile(obj.FileList, obj.CompileBinDirectory, obj.Reporting);
        end
    end
    
    
end

