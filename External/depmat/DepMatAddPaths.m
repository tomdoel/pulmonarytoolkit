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
    myPaths = getSubfolders(path_root);
    allPathsToAdd = [allPathsToAdd, myPaths];
    
    for repoIndex = 1 : numel(baseFolderList)
        repoName = repoNameList{repoIndex};
        doAddPaths = forceUpdate;
        if ~ismember(repoName, DepMat_PathsHaveBeenSet)
            doAddPaths = true;
            DepMat_PathsHaveBeenSet{end + 1} = repoName;
        end
        if doAddPaths
            repoPaths = getSubfolders(baseFolderList{repoIndex});
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

function subFolders = getSubfolders(baseFolder)
    subFolders = GetRecursiveListOfDirectories(baseFolder);
end

function AddToPath(pathList)    
    % Add all the paths together (much faster than adding them individually)
    if ~isempty(pathList)
        addpath(pathList{:});
    end
end

function dirsFound = GetRecursiveListOfDirectories(root_path)
    % Returns a list of all subdirectories in the specified directory, its
    % subdictories and so on

    dirsToDo = {root_path};
    dirsFound = {};
    while ~isempty(dirsToDo)
        next_dir = dirsToDo{end};
        dirsToDo(end) = [];
        dirsFound{end + 1} = next_dir;
        this_dir_list = GetListOfDirectories(next_dir);
        for index = 1 : numel(this_dir_list)
            dirsToDo{end + 1} = fullfile(next_dir, this_dir_list{index});
        end
    end
end

function dir_list = GetListOfDirectories(path)
    % Returns a list of subdirectories in the specified directory
            
    files = dir(fullfile(path, '*'));
    number_files = length(files);
    dir_list = {};
    for i = 1 : number_files
        filename = files(i).name;
        isdir = files(i).isdir;
        if (filename(1) ~= '.' && isdir)
            dir_list{end + 1} = filename; %#ok<AGROW>
        end
    end
end
