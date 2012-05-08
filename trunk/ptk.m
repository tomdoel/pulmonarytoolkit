% tdptk. Runs the Pulmonary Toolkit user interface
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
TDAddPtkPaths;

% Verify that an appropriate version of Matlab is being run
TDCheckMatlabVersion;

% Run the toolkit gui
TDPTKGui;