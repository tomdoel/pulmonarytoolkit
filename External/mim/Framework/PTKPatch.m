classdef PTKPatch
    % Interface for sharing image edits with other PTK users.
    %
    % Edited results can be shared with other users by exporting the edited result as
    % a PTKPatch object. This can then be imported by the other user.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2014.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (Abstract)
        Schema
        PatchType
    end
end

