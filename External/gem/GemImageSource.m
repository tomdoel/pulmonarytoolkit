classdef GemImageSource < CoreBaseClass
    % Wraps a PTKImage class for GUI visualisation
    %
    % .. Licence
    %    -------
    %    Part of GEM. https://github.com/tomdoel/gem
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    events
        NewImage        % An event to indicate the image has been replaced
        ImageModified   % An event to indicate the image has been modified
    end
    
    properties (SetObservable)
        Image           % The PTKImage object containing the image volume
    end
    
    properties (Access = private)
        % When the image pointer changes, the image change listener will be invalid, so need to create a new one
        ImageChangedListener % The listener for changes to the image
    end
    
    methods
        
        function obj = GemImageSource
            % Listen for changes to the image pointers
            obj.AddPostSetListener(obj, 'Image', @obj.ImagePointerChangedCallback);
            
            % The image object must be created here, not in the properties section, to
            % prevent Matlab creating a circular dependency (see Matlab solution 1-6K9BQ7)
            % Also note that theis will trigger the above pointer change callback, which
            % will set up the pixel data change callback
            obj.Image = PTKImage();
        end
        
        function delete(obj)
            CoreSystemUtilities.DeleteIfValidObject(obj.ImageChangedListener);
        end
    end
    
    methods (Access = private)
        function ImagePointerChangedCallback(obj, ~, ~)
            obj.ImageHasBeenReplaced;
        end
        
        function ImageModifiedCallback(obj, ~, ~)
            notify(obj, 'ImageModified');
        end

        function ImageHasBeenReplaced(obj)
            % When the image pointer is changed, we not only need to notify
            % that the image has been changed, but we also need to create a
            % new listener for image modifications, since the old pointer
            % points to the old image pointer
            
            % Check that this image is the correct class type
            if ~isa(obj.Image, 'PTKImage')
                error('The image must be of class PTKImage');
            end
            
            % Remove existing listener
            CoreSystemUtilities.DeleteIfValidObject(obj.ImageChangedListener);
            
            % Listen for image change events
            obj.ImageChangedListener = addlistener(obj.Image, 'ImageChanged', @obj.ImageModifiedCallback);

            % Fire a new image event
            notify(obj, 'NewImage');
        end 
        
    end
end