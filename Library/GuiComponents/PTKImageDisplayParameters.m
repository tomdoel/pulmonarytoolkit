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
    end
    
    methods
        function obj = PTKImageDisplayParameters
            % Listen for changes to the parameters
            obj.AddPostSetListener(obj, 'Opacity', @obj.OpacityChangedCallback);
            obj.AddPostSetListener(obj, 'ShowImage', @obj.ShowImageChangeCallback);
        end
    end
    
    methods (Access = private)
        function OpacityChangedCallback(obj, ~, ~)
            notify(obj, 'OpacityChanged');
        end
        function ShowImageChangeCallback(obj, ~, ~)
            notify(obj, 'ShowImageChanged');
        end
    end
end