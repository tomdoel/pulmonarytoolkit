classdef GemMarkerDisplayParameters < CoreBaseClass
    % GemMarkerDisplayParameters. Parameters for visualising marker points
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (SetObservable)
        ShowMarkers = false
        ShowLabels = false
    end
end