classdef DepMat
    % DepMat A class used to update git repositories
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    
    properties (SetAccess = private)
        RepoList
        RootSourceDir
        RepoUpdaterList
        RepoDirList
        RepoNameList
    end
    
    methods
        function obj = DepMat(repoList, rootSourceDir)
            obj.RepoList = repoList;
            obj.RootSourceDir = rootSourceDir;
            DepMat.fixCurlPath;
            
            obj.RepoDirList = cell(1, numel(obj.RepoList));
            obj.RepoNameList = cell(1, numel(obj.RepoList));
            obj.RepoUpdaterList = DepMatRepositoryUpdater.empty;
            
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoList(repoIndex);
                repoCombinedName = repo.FolderName;
                repoSourceDir = fullfile(obj.RootSourceDir, repoCombinedName);
                repo = DepMatRepositoryUpdater(repoSourceDir, repo);
                obj.RepoUpdaterList(repoIndex) = repo;
                obj.RepoDirList{repoIndex} = repoSourceDir;
                obj.RepoNameList{repoIndex} = repoCombinedName;
            end
        end
        
        function statusList = getAllStatus(obj)
            statusList = DepMatStatus.empty;
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoUpdaterList(repoIndex);
                statusList(repoIndex) = repo.getStatus;
            end
        end
        
        function success = updateAll(obj)
            success = true;
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoUpdaterList(repoIndex);
                success = success && repo.updateRepo;
            end
        end
        
        function anyChanged = cloneOrUpdateAll(obj)
            anyChanged = false;
            
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoUpdaterList(repoIndex);
                [~, changed] = repo.cloneOrUpdate;
                anyChanged = anyChanged || changed;
            end

        end
    end
    
    methods (Static)
        function [success, output] = execute(command)
            [return_value, output] = system(command);
            success = return_value == 0;
            if ~success
                if strfind(output, 'Protocol https not supported or disabled in libcurl')
                    disp('! You need to modify the the DYLD_LIBRARY_PATH environment variable to point to a newer version of libcurl. The version installed with Matlab does not support using https with git.');
                end
            end
        end

        function installed = isGitInstalled
            if ispc
                command = 'where git';
            else
                command = 'which git';
            end
            
            installed = DepMat.execute(command);
        end
        
        function fixCurlPath
            % Matlab's curl configuration doesn't include https so git will not work.
            % We need to add the system curl configuration directory earlier in the
            % path so that it picks up this one instead of Matlab's
            
            try
                if ismac
                    pathName = 'DYLD_LIBRARY_PATH';
                    binDir = '/usr/lib';
                elseif isunix
                    pathName = 'LD_LIBRARY_PATH';
                    binDir = '/usr/lib';
                else
                    pathName = [];
                    binDir = [];
                end
                
                if ~isempty(pathName)
                    currentLibPath = getenv(pathName);
                    if (7 == exist(binDir, 'dir')) && ~strcmp(currentLibPath(1:length(binDir) + 1), [binDir ':'])
                        setenv(pathName, [binDir ':' currentLibPath]);
                    end
                end
            catch exception
                disp(['DepMat:fixCurlPath error: ' exception.message]);
            end
        end
    end
    
end

