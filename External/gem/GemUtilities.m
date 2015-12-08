classdef GemUtilities
    % GemUtilities Utility functions for use with GEM classes
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
        
    methods (Static)
        function [dimxIndex, dimYindex, dimZindex] = GetXYDimensionIndex(orientation)
            switch orientation
                case GemImageOrientation.XZ
                    dimxIndex = 2;
                    dimYindex = 3;
                    dimZindex = 1;
                case GemImageOrientation.YZ
                    dimxIndex = 1;
                    dimYindex = 3;
                    dimZindex = 2;
                case GemImageOrientation.XY
                    dimxIndex = 2;
                    dimYindex = 1;
                    dimZindex = 3;
            end
        end
                
        function rgbImage = AddHighlightToRGBImage(rgbImage, highlightMaskImage, highlightColour)
            for index = 1 : 3
                imageLayer = rgbImage(:, :, index);
                imageLayer(highlightMaskImage) = highlightColour(index);
                rgbImage(:, :, index) = imageLayer;
            end
        end
        
        function imageHighlight = GetRGBImageHighlight(originalImage, backgroundColour)
            background = (originalImage(:, :, 1) == backgroundColour(1)) & (originalImage(:, :, 2) == backgroundColour(2)) & (originalImage(:, :, 3) == backgroundColour(3));
            
            diskElement = CoreImageUtilities.CreateDiskStructuralElement([1, 1], 4);
            imageHighlight = imdilate(~background, diskElement);
            imageHighlight = imageHighlight & background;
        end
        
        function originalImage = HighlightRGBImage(originalImage, backgroundColour)
            imageDilated = GemUtilities.GetRGBImageHighlight(originalImage, backgroundColour);
            highlightColour = [255, 255, 0];
            for index = 1 : 3
                imageLayer = originalImage(:, :, index);
                imageLayer(imageDilated) = highlightColour(index);
                originalImage(:, :, index) = imageLayer;
            end
        end
        
        function borderImage = GetBorderImage(imageSize, borderSize)
            borderImage = false(imageSize);
            borderImage(1:1+borderSize, :) = true;
            borderImage(end-borderSize+1:end, :) = true;
            borderImage(:, 1:borderSize) = true;
            borderImage(:, end-borderSize+1:end) = true;
        end

        function rgbImage = ConvertImageToButtonImage(border, backgroundColour, borderColour, maskImage, rgbImage)            
            buttonHeight = size(maskImage, 1);
            buttonBackgroundColour = uint8(255*backgroundColour);
            buttonTextColour = 150*[1, 1, 1];
            finalFadeFactor = 0.3;
            rgbImageFactor = finalFadeFactor*ones(size(rgbImage));
            xRange = 1 : -1/(buttonHeight - 1) : 0;
            xRange = (1-finalFadeFactor)*xRange + finalFadeFactor;
            rgbImageFactor(:, 1:buttonHeight, :) = repmat(xRange, [buttonHeight, 1, 3]);
            rgbImage = uint8(round(rgbImageFactor.*double(rgbImage)));
            
            rgbImage = GemUtilities.AddBorderToRGBImage(rgbImage, maskImage, border, buttonBackgroundColour, buttonTextColour, borderColour, []);
        end
        
        function rgbImage = AddBorderToRGBImage(rgbImage, maskImage, borderSize, buttonBackgroundColour, buttonForegroundColour, borderColour, contrastColour)
            for c = 1 : 3
                colorSlice = rgbImage(:, :, c);
                colorSlice(maskImage(:) == 0) = buttonBackgroundColour(c);
                colorSlice(maskImage(:) == 255) = buttonForegroundColour(c);
                rgbImage(:, :, c) = colorSlice;
                
                if borderSize > 0
                    if ~isempty(contrastColour)
                        rgbImage(1+borderSize+1, :, c) = contrastColour(c);
                        rgbImage(end-borderSize-1, :, c) = contrastColour(c);
                        rgbImage(:, borderSize+1, c) = contrastColour(c);
                        rgbImage(:, end-borderSize:end, c) = contrastColour(c);
                    end
                    rgbImage(1:1+borderSize, :, c) = borderColour(c);
                    rgbImage(end-borderSize+1:end, :, c) = borderColour(c);
                    rgbImage(:, 1:borderSize, c) = borderColour(c);
                    rgbImage(:, end-borderSize+1:end, c) = borderColour(c);
                    
                end
            end
        end

        function rgbImage = GetBlankRGBImage(buttonHeight, buttonWidth)
            buttonBackgroundColour = [0.0, 0.129, 0.278];
            buttonBackgroundColourShift = shiftdim(buttonBackgroundColour, -1);
            blankImage = ones([buttonHeight, buttonWidth]);
            rgbImage = repmat(buttonBackgroundColourShift, [buttonHeight, buttonWidth, 1]).*repmat(blankImage, [1, 1, 3]);
            rgbImage = uint8(255*rgbImage);
        end
        
        function rgbImage = GetBlankButtonImage(buttonWidth, buttonHeight, border, backgroundColour, borderColour)
            buttonImage = zeros(buttonHeight, buttonWidth, 'uint8');
            [rgbImage, ~] = CoreImageUtilities.GetLabeledImage(buttonImage, []);
            rgbImage = GemUtilities.ConvertImageToButtonImage(border, backgroundColour, borderColour, buttonImage, rgbImage);
        end
        
        function frame = CaptureFigure(figureHandle, rectScreenpixels)
            % Use Matlab's undocumented hardcopy() function to capture an image from a figure, avoiding the limitations of getframe()
            % Store current figure settings
            oldRenderer     = get(figureHandle, 'Renderer');
            oldResizeFcn = get(figureHandle, 'ResizeFcn');
            oldPaperPositionMode = get(figureHandle, 'PaperPositionMode');
            oldPaperOrientation  = get(figureHandle, 'PaperOrientation');
            oldInvertHardcopy = get(figureHandle, 'InvertHardcopy');
            
            % Choose renderer
            if strcmpi(oldRenderer, 'painters')
                imageRenderer = '-dzbuffer';
            else
                imageRenderer = ['-d', oldRenderer];
            end
            
            % Change figure settings
            set(figureHandle, 'PaperPositionMode', 'auto', 'PaperOrientation', 'portrait', ...
                'InvertHardcopy', 'off', 'ResizeFcn', '');

            % Compute the DPI
            set(0, 'units', 'pixels')  
            screen_size_pixels = get(0, 'screensize');
            set(0, 'units', 'inches')
            screen_size_inches = get(0, 'screensize');
            dpi = round(screen_size_pixels(3)/screen_size_inches(3));
            
            % Get image
            cdata = hardcopy(figureHandle, imageRenderer, ['-r' int2str(dpi)]);
            frame = im2frame(cdata);
            
            % Restore figure settings
            set(figureHandle, 'PaperPositionMode', oldPaperPositionMode, 'PaperOrientation', oldPaperOrientation, ...
                'InvertHardcopy', oldInvertHardcopy, 'ResizeFcn', oldResizeFcn);
            
            frameHeight = size(frame.cdata, 1);
            cdata = frame.cdata(2 + frameHeight - (rectScreenpixels(2)+rectScreenpixels(4)) : frameHeight - rectScreenpixels(2), rectScreenpixels(1):rectScreenpixels(1)+rectScreenpixels(3)-1, :);
            frame.cdata = cdata;
        end       
    end
end

