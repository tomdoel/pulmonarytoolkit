function PulmonaryToolkitAPI(script_name, varargin)
% PulmonaryToolkitAPI. Runs the Pulmonary Toolkit API
%
%
%     Licence
%     -------
%     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
%     Author: Tom Doel, 2012.  www.tomdoel.com
%     Distributed under the GNU GPL v3 licence. Please see website for details.
%

    if ~isdeployed
        % Add all necessary paths
        PTKAddPaths;
    end

    % Create the main PTK object without a progress dialog
    ptk_main = PTKMain(CoreReporting);
    
    if nargin < 2
        parameters = [];
    end
    
    % Run the specified script with the specified parameter string
    results = ptk_main.RunScript(script_name, varargin{:});
end