function PulmonaryToolkit
% PTKRun. Runs the Pulmonary Toolkit user interface
%
%
%     Licence
%     -------
%     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
%     Author: Tom Doel, 2012.  www.tomdoel.com
%     Distributed under the GNU GPL v3 licence. Please see website for details.
%

    if ~isdeployed
        % Clear command window
        clc

        % Add all necessary paths
        PTKAddPaths;

        % Update the repository
        updated = PTKUpdate;

        % We may need to add new paths as a result of an update
        if updated
            PTKAddPaths force;
        end
    end

    % Create the splash screen - do this early so the user knows something is
    % hapenning
    splash_screen = PTKSplashScreen.GetSplashScreen(PTKAppDef);
    splash_screen.ShowAndHold('Initialising');

    % Verify that an appropriate version of Matlab is being run
    PTKCheckMatlabVersion;

    % Run the toolkit gui
    PTKGui(splash_screen);
    
    if ~isdeployed
        % Remove our handle to the splash screen and the GUI
        clear splash_screen ans
    end
end