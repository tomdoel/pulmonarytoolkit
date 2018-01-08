classdef PTKImageUtilities
    % PTKImageUtilities. Legacy funciton support
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
        
    methods (Static)

        function [results, combined_image] = ComputeDice(image_1, image_2)
            [results, combined_image] = MimImageUtilities.ComputeDice(image_1, image_2);
        end
        
        function results = ComputeBorderError(image_1, image_2)
            results = MimImageUtilities.ComputeBorderError(image_1, image_2);
        end
    end
end

