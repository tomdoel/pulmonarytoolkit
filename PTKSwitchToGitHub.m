function PTKSwitchToGitHub

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

    
    if isGitInstalled
        answer = questdlg('PTK has moved to GitHub. Should I migrate your PTK codebase now?','PTK has moved to GitHub','Do not migrate','Migrate','Migrate');
        if strcmp(answer, 'Migrate')
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
        else
            msgbox('Please re-run ptk to migrate your codebase, or clone the new codebae yourself from https://github.com/tomdoel/pulmonarytoolkit', 'Pulmonary Toolkit');
        end
    else
        msgbox('PTK has moved to GitHub. I could not find Git on your path. Please install Git and re-run and I will try to update your codebase. Alternatively, clone PTK yourself from https://github.com/tomdoel/pulmonarytoolkit', 'Pulmonary Toolkit');
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
    if (7 == exist('usr/local/bin', 'dir'))
        setenv('DYLD_LIBRARY_PATH', ['/usr/local/bin;' getenv('DYLD_LIBRARY_PATH')]);
    end

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
    
    success = true;
end

function installed = isGitInstalled
    installed = execute('which git');
end

function success = execute(command)
    return_value = system(command);
    success = return_value == 0;
end