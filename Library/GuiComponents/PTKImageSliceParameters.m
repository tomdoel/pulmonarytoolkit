classdef PTKImageSliceParameters < CoreBaseClass
    % PTKImageSliceParameters. Parameters for extracting a 2D slice from a
    % 3D volume
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    events
         OrientationChanged
         SliceNumberChanged
    end
    
    properties (SetObservable)
        Orientation = PTKImageOrientation.Coronal
        SliceNumber = [1, 1, 1] % The currently shown slice in 3 dimensions
    end
    
    methods
        function obj = PTKImageSliceParameters
            % Listen for changes to the parameters
            obj.AddPostSetListener(obj, 'Orientation', @obj.OrientationChangedCallback);
            obj.AddPostSetListener(obj, 'SliceNumber', @obj.SliceNumberChangedCallback);
        end
    end
    
    methods (Access = private)
        function OrientationChangedCallback(obj, ~, ~)
            notify(obj, 'OrientationChanged');
        end
        
        function SliceNumberChangedCallback(obj, ~, ~)
            notify(obj, 'SliceNumberChanged');
        end
    end
end