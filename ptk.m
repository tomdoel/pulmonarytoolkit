% ptk. Runs the Pulmonary Toolkit user interface
%
%
%     Licence
%     -------
%     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
%     Author: Tom Doel, 2012.  www.tomdoel.com
%     Distributed under the GNU GPL v3 licence. Please see website for details.
%


% Clear command window
clc

% Add all necessary paths
PTKAddPaths;

% Create the splash screen - do this early so the user knows something is
% hapenning
splash_screen = PTKSplashScreen.GetSplashScreen;
splash_screen.ShowAndHold('Initialising');

% Verify that an appropriate version of Matlab is being run
PTKCheckMatlabVersion;

% Run the toolkit gui
PTKGui(splash_screen);

% Remove our handle to the splash screen and the GUI
clear splash_screen ans