classdef GemMarkerDisplayParameters < CoreBaseClass
    % Parameters for visualising marker points
    %
    % .. Licence
    %    -------
    %    Part of GEM. https://github.com/tomdoel/gem
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    properties (SetObservable)
        ShowMarkers = false
        ShowLabels = false
    end
end