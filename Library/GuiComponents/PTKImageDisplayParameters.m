classdef PTKImageDisplayParameters < CoreBaseClass
    % PTKImageDisplayParameters. Parameters for visualising an image
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    events
        OpacityChanged
        ShowImageChanged
    end
    
    properties (SetObservable)
        Opacity = 100
        ShowImage = true
        BlackIsTransparent = false
        OpaqueColour
    end
end