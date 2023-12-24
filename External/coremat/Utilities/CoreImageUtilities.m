classdef CoreImageUtilities
    % Utility functions related to displaying images
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
        
    methods (Static)
        
        function [rgbImage, alpha] = GetLabeledImage(image, map)
            % Returns an RGB image from a colormap matrix
            if isempty(map)
                if isa(image, 'double') || isa(image, 'single')
                    rgbImage = CoreLabel2Rgb(round(image));
                else
                    rgbImage = CoreLabel2Rgb(image);
                end
                alpha = int8(image ~= 0);
            else
                if isa(image, 'double') || isa(image, 'single')
                    rgbImage = CoreLabel2Rgb(map(round(image + 1)));
                else
                    rgbImage = CoreLabel2Rgb(map(image + 1));
                end
                alpha = int8(image ~= 0);
            end
        end
        
        function [rgbImage, alpha] = GetBWImage(image)
            % Returns an RGB image from a greyscale matrix
            
            rgbImage = (cat(3, image, image, image));
            alpha = ones(size(image));
        end

        function [rgbImage, alpha] = GetColourMap(image, imageLimits)
            % Returns an RGB image from a scaled floating point scalar image
 
            imageLimits(1) = min(0, imageLimits(1));
            imageLimits(2) = max(0, imageLimits(2));
            positiveMask = image >= 0;
            rgbImage = zeros([size(image), 3], 'uint8');
            positiveImage = abs(double(image))/abs(double(imageLimits(2)));
            negativeImage = abs(double(image))/abs(double(imageLimits(1)));
            rgbImage(:, :, 1) = uint8(positiveMask).*(uint8(255*positiveImage));
            rgbImage(:, :, 3) = uint8(~positiveMask).*(uint8(255*negativeImage));
            
            alpha = int8(min(1, abs(max(positiveImage, negativeImage))));
        end
        
        function ballElement = CreateBallStructuralElement(voxelSize, sizeMm)
            if numel(sizeMm) == 1
                sizeMm = [sizeMm, sizeMm, sizeMm];
            end
            strelSizeVoxels = ceil((sizeMm - voxelSize)./(2*voxelSize));
            ispan = -strelSizeVoxels(1) : strelSizeVoxels(1);
            jspan = -strelSizeVoxels(2) : strelSizeVoxels(2);
            kspan = -strelSizeVoxels(3) : strelSizeVoxels(3);
            [i, j, k] = ndgrid(ispan, jspan, kspan);
            i = i.*voxelSize(1)./sizeMm(1);
            j = j.*voxelSize(2)./sizeMm(2);
            k = k.*voxelSize(3)./sizeMm(3);
            ballElement = zeros(size(i));
            ballElement(:) = sqrt(i(:).^2 + j(:).^2 + k(:).^2);
            ballElement = ballElement <= (1/2);
        end
        
        function disk_element = CreateDiskStructuralElement(pixelSize, sizeMm)
            if numel(sizeMm) == 1
                sizeMm = [sizeMm, sizeMm];
            end
            
            strel_size_voxels = ceil((sizeMm - pixelSize)./(2*pixelSize));
            ispan = -strel_size_voxels(1) : strel_size_voxels(1);
            jspan = -strel_size_voxels(2) : strel_size_voxels(2);
            [i, j] = ndgrid(ispan, jspan);
            i = i.*pixelSize(1)./sizeMm(1);
            j = j.*pixelSize(2)./sizeMm(2);
            disk_element = zeros(size(i));
            disk_element(:) = sqrt(i(:).^2 + j(:).^2);
            disk_element = disk_element <= (1/2);
        end
        
        
    end
end

