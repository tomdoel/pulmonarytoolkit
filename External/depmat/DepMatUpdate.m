function DepMatUpdate(repoList, varargin)
    % DepMatUpdate. Clones or updates all repositories in a DepMatRepo list 
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
   
    
    forcePathUpdate = nargin > 1 && strcmp(varargin{1}, 'force');
    
    rootSourceDir = fullfile(getUserDirectory, 'depmat', 'Source');
    
    depMat = DepMat(repoList, rootSourceDir);
    if ~depMat.isGitInstalled
        msgbox('Cannot find git');
        return;
    end
    
    anyChanged = depMat.cloneOrUpdateAll;
    repoDirList = depMat.RepoDirList;
    repoNameList = depMat.RepoNameList;
    
    forcePathUpdate = forcePathUpdate || anyChanged;
    
    DepMatAddPaths(repoDirList, repoNameList, forcePathUpdate);
end

function home_directory = getUserDirectory
    % Returns a path to the user's home folder
    if (ispc)
        home_directory = getenv('USERPROFILE');
    else
        home_directory = getenv('HOME');
    end
end


