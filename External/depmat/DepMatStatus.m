classdef DepMatStatus
    % DepMatStatus. Enumeration for the current status of a git repository
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    enumeration
        GitNotFound
        DirectoryNotFound
        NotUnderSourceControl
        FetchFailure
        UpToDate
        UpdateAvailable
        LocalChanges
        Conflict
        GitFailure
    end
end

