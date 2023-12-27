classdef CoreWrapper < handle
    % CoreWrapper. A simple handle class allowing images to be passed by reference
    %
    %     For passing images and other large data structures by reference, in
    %     order to avoid unnecessary copying of data.
    %
    %     While Matlab uses a copy-on-write mechanism for value objects
    %     which should prevent unecessary copying, this wrapper class also
    %     allows the contents to be modified without copying.
    %
    %     Example
    %     -------
    %
    %     This example shows how to use a CoreWrapper to pass an image to a sub
    %     function. As CoreWrapper is a handle class, only the reference is passed
    %     to the subfunction, avoiding copying of the large image matrix.
    %     
    %     image_wrapper = CoreWrapper();
    %     image_wrapper.RawImage = <large image matrix>
    %     SubFunction(image_wrapper);
    %
    %     function SubFunction(image_wrapper)
    %         Process(image_wrapper.RawImage);
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        RawImage
    end
end

