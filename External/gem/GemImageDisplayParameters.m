classdef GemImageDisplayParameters < CoreBaseClass
    % Parameters for visualising an image
    %
    % .. Licence
    %    -------
    %    Part of GEM. https://github.com/tomdoel/gem
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    events
        OpacityChanged
        ShowImageChanged
    end
    
    properties (SetObservable)
        Window = 1600          % The image window (in HU for CT images)
        Level = -600           % The image level (in HU for CT images)
        Opacity = 100
        ShowImage = true
        BlackIsTransparent = false
        OpaqueColour
    end
end