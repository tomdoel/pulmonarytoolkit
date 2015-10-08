classdef CoreImageUtilities
    % CoreImageUtilities. Utility functions related to displaying images
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
        
    methods (Static)
        
        function [rgb_image, alpha] = GetLabeledImage(image, map)
            % Returns an RGB image from a colormap matrix
            if isempty(map)
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = CoreLabel2Rgb(round(image));
                else
                    rgb_image = CoreLabel2Rgb(image);
                end
                alpha = int8(image ~= 0);
            else
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = CoreLabel2Rgb(map(round(image + 1)));
                else
                    rgb_image = CoreLabel2Rgb(map(image + 1));
                end
                alpha = int8(image ~= 0);
            end
        end
    end
end

