function PTKSwitchToGitHub(varargin)

    % PTKSwitchToGitHub. A script to switch a Google Code svn checkout to a
    %     GitHub git checkout
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if ~checkIfGitRepoExists
        if ~checkDoNotUpdate || (nargin > 0 && strcmp(varargin{1}, 'force'))
            clearDoNotUpdate;
            if isGitInstalled
                answer = questdlg('PTK has moved to GitHub. Should I migrate your PTK codebase now?','PTK has moved to GitHub','Later','Do not ask me again', 'Migrate','Migrate');
                if strcmp(answer, 'Do not ask me again')
                    setDoNotUpdateFlag
                elseif strcmp(answer, 'Migrate')
                    answer2 = questdlg('Please ensure you have any important changes backed up. If successful, the migration should preserve any local changes you have made to PTK, but I cannot guarantee this!','Pulmonary Toolkit','Cancel migration','Migrate','Migrate');
                    if strcmp(answer2, 'Migrate')
                        if SwitchToGitHub
                            msgbox('Successfully migrated to GitHub. Please now use Git to pull updates to PTK', 'Migrated to GitHub');
                        else
                            msgbox('Sorry, there was a problem migrating your codebase. Please clone the new codebae yourself from https://github.com/tomdoel/pulmonarytoolkit', 'Failed to migrate to GitHub');
                        end
                    else
                        msgbox('Please re-run ptk to migrate your codebase, or clone the new codebae yourself from https://github.com/tomdoel/pulmonarytoolkit', 'Pulmonary Toolkit');
                    end
                end
            else
                msgbox('PTK has moved to GitHub. I could not find Git on your path. Please install Git and re-run and I will try to update your codebase. Alternatively, clone PTK yourself from https://github.com/tomdoel/pulmonarytoolkit', 'Pulmonary Toolkit');
            end
        end
    end
end

function success = SwitchToGitHub
    success = false;
    
    if ~isGitInstalled
        disp('Cannot update as git is not installed or not in the path');
        return;
    end

    % Matlab's curl configuration doesn't include https so git will not work.
    % We need to add the system curl configuration directory earlier in the
    % path so that it picks up this one instead of Matlab's
    fixCurlPath;

    [repo_path, ~, ~] = fileparts(mfilename('fullpath'));

    if isempty(repo_path)
        disp('Can''t find the PTK checkout directory');
        return;
    end

    if 7 ~= exist(fullfile(repo_path, '.svn'), 'dir')
        disp('Can''t find the PTK Google Code directory');
        return;
    end

    cd(repo_path);

    if 7 == exist(fullfile(repo_path, '.git'), 'dir')
        disp('There is already a git checkout at this folder.');
        return;
    end

    if ~execute('git init')
        disp('Could not initialise the repository');
        return;
    end
    
    if ~execute('git remote add origin https://github.com/tomdoel/pulmonarytoolkit')
        disp('Could not add the GitHub remote');
        return;
    end
    
    if ~execute('git fetch')
        disp('Could not fetch from the GitHub repository');
        return;
    end
    
    if ~execute('git reset origin/googlecode-head')
        disp('Could not reset the head');
        return;
    end
    
    if ~execute('git checkout -b master')
        disp('Could not checkout the master branch');
        return;
    end
    
    success = true;
end

function installed = isGitInstalled
    installed = execute('which git');
end

function success = execute(command)
    [return_value, ~] = system(command);
    success = return_value == 0;
end

function fixCurlPath
    % Matlab's curl configuration doesn't include https so git will not work.
    % We need to add the system curl configuration directory earlier in the
    % path so that it picks up this one instead of Matlab's
    currentLibPath = getenv('DYLD_LIBRARY_PATH');
    binDir = '/usr/lib';
    if (7 == exist(binDir, 'dir')) && ~strcmp(currentLibPath(1:length(binDir) + 1), [binDir ':'])
        setenv('DYLD_LIBRARY_PATH', [binDir ':' currentLibPath]);
    end
end

function setDoNotUpdateFlag
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);    
    filename = fullfile(path_root, 'do-not-update');
    fileHandle = fopen(filename, 'w');
    fclose(fileHandle);
end

function doNotUpdate = checkDoNotUpdate
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    filename = fullfile(path_root, 'do-not-update');
    doNotUpdate = (2 == exist(filename, 'file'));
end

function clearDoNotUpdate
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    filename = fullfile(path_root, 'do-not-update');
    if (2 == exist(filename, 'file'))
        delete(filename);
    end
end

function repoExists = checkIfGitRepoExists
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    filename = fullfile(path_root, '.git');
    repoExists = (7 == exist(filename, 'dir'));
end
