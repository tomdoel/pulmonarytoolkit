function DepMatAddPaths(baseFolderList, repoNameList, forceUpdate)
    % DepMatAddPaths. Adds paths for all subfolders in given repositories
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    

    % We store a list of repos whose paths have already been added
    persistent DepMat_PathsHaveBeenSet
    if isempty(DepMat_PathsHaveBeenSet)
        DepMat_PathsHaveBeenSet = {};
    end

    allPathsToAdd = {};

    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    myPaths = genpath(path_root);
    allPathsToAdd = [allPathsToAdd, myPaths];
    
    for repoIndex = 1 : numel(baseFolderList)
        repoName = repoNameList{repoIndex};
        doAddPaths = forceUpdate;
        if ~ismember(repoName, DepMat_PathsHaveBeenSet)
            doAddPaths = true;
            DepMat_PathsHaveBeenSet{end + 1} = repoName;
        end
        if doAddPaths
            repoPaths = genpath(baseFolderList{repoIndex});
            allPathsToAdd = [allPathsToAdd, repoPaths];
        end
        
    end
    filtered_paths = {};
    for nextPath = allPathsToAdd
        if isempty(strfind(nextPath{1}, [filesep '+'])) && isempty(strfind(nextPath{1}, [filesep '@']))
            filtered_paths{end + 1} = nextPath{1};
        end
    end
    
    AddToPath(filtered_paths);
end

function AddToPath(pathList)    
    % Add all the paths together (much faster than adding them individually)
    if ~isempty(pathList)
        addpath(pathList{:});
    end
end
