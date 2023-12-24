classdef GemImageSliceParameters < CoreBaseClass
    % Parameters for extracting a 2D slice from a 3D volume
    %
    % .. Licence
    %    -------
    %    Part of GEM. https://github.com/tomdoel/gem
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    properties (SetObservable)
        Orientation = GemImageOrientation.XZ
        SliceNumber = [1, 1, 1] % The currently shown slice in 3 dimensions
        UpdateLock
    end
end