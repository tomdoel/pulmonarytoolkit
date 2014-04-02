function result = PTKLevelSets2D(original_image, initial_mask, bounds, figure_handle, reporting)
    % PTKLevelSets2D. 2D level set algorithm based on image gradient
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    result = initial_mask.BlankCopy;
    result.ImageType = PTKImageType.Colormap;
    
    initial_mask.ChangeRawImage(logical(initial_mask.RawImage));
    
    options = [];
    options.num_iterations = 1000;
    options.std_dev = 2;
    options.c = 0; % No speed set. Typical value of =0.5
    options.dt = 0.5;
    options.k = 2;
    options.alpha = 0.01;
    options.upper_bound = single(bounds(2)); % Typical value 330;
    options.lower_bound = single(bounds(1)); % Typical value 0;
    options.curv_multiple = 1;
    
    result_raw = SolveLevelSets(original_image, initial_mask, options, figure_handle, reporting);
    
    result.ChangeRawImage(result_raw);
end

function result = SolveLevelSets(original_image, initial_mask, options, figure_handle, reporting)
    initial_mask = initial_mask.RawImage;
    im = double(original_image.RawImage);
    
    if ~isempty(figure_handle)
        figure(figure_handle);
        imagesc(im); hold on; colormap gray; colorbar; axis square;
    end
    
    if (nargin < 2)
        initial_mask = GetInitialContourMask(im);
    end
    
    psi = initialise(initial_mask);
    
    force_handle = @force_combined;
    gaussian_im = GaussianFilter(im, options.std_dev);
    
    im = gaussian_im;
    
    contour_handle = [];
    
    if ~isempty(figure_handle)
        hold off;
        imagesc(im);
        hold on;
    end
    
    iter = 0;
    converged = false;
    converged_count = 0;
    old_result = [];
    
    while (iter < options.num_iterations) && (~converged)
        iter = iter + 1;
        
        psi = NextContour(psi, im, gaussian_im, options, force_handle);
        
        if any(isnan(psi))
            reporting.ShowMessage('PTKLevelSets2D:NanFound', 'Terminating the level set algorthm because a NaN was found.');
            converged = true;
        end
        
        result = (psi > 0);
        if IsTouchingSides(result)
            reporting.ShowMessage('PTKLevelSets2D:BoundaryConnection', 'Terminating the level set algorthm because the segmentation connected with the image boundary.');
            return;
        end
        
        
        if (mod(iter, 10) == 0)
            
            % If there hasn't been any change in the segmentation for the last
            % 50 iterations then we terminate early
            result = (psi > 0);
            
            if ~isempty(old_result)
                diff = abs(result - old_result);
                if ~any(diff(:))
                    converged_count = converged_count + 1;
                else
                    converged_count = 0;
                end
                
                if converged_count > 5
                    converged = true;
                    disp('Converged: terminating');
                end
            end
            
            psi = re_initialise(psi);
            old_result = result;
        end
        
        if ~isempty(figure_handle)
            if (mod(iter, 20) == 0)
                if ~isempty(contour_handle)
                    delete(contour_handle);
                end
                [~, contour_handle] = contour(psi,[0 0], 'r');
                title(['Iteration ' num2str(iter)]);
                drawnow;
            end
        end
        
    end
    
    result = (psi > 0);
end



function is_touching_sides = IsTouchingSides(image_to_check)
    is_touching_sides = CheckSide(image_to_check(:, 1)) || CheckSide(image_to_check(:, end)) ...
        || CheckSide(image_to_check(1, :)) || CheckSide(image_to_check(end, :));
end

function any_nonzero = CheckSide(side)
    any_nonzero = any(side(:));
end



function UpdateOverlayImage(phi, template, reporting)
    mask_ini = (phi>0);
    template.ChangeRawImage(mask_ini);
    reporting.UpdateOverlaySubImage(template);
    drawnow;
end

function next_psi = NextContour(psi, im, gaussian_im, options, force_function)
    [gX, gY] = gradient(psi);
    modgrad = sqrt(gX.^2 + gY.^2);
    next_psi = psi - force_function(psi, im, gaussian_im, options).*modgrad*options.dt;
end

function F = force_curvature(psi, im, gaussian_im, options)
    F = options.c + options.curv_multiple*curvature(psi);
end

function F = force_gradient(psi, im, gaussian_im, options)
    [gX, gY] = gradient(gaussian_im);
    modgrad = sqrt(gX.^2 + gY.^2);
    
    force_curv = force_curvature(psi, im, gaussian_im, options);
    g = options.k./(options.k + modgrad);
    F = force_curv.*g;
end

function F = force_region(psi, im, gaussian_im,  options)
    in_region = im < (options.lower_bound + (options.upper_bound - options.lower_bound)/2);
    F = (2*in_region - 1).*im - in_region*options.lower_bound + (1 - in_region)*options.upper_bound;
    F = -F;
end

function F = force_combined(psi, im, gaussian_im, options)
    F = options.alpha*force_region(psi, im, gaussian_im, options) + (1 - options.alpha)*force_gradient(psi, im, gaussian_im, options);
end

function F = force_basic(psi, im, gaussian_im, options)
    F = force_curvature(psi, im, gaussian_im, options);
end

function mask = GetInitialContourMask(im)
    [x,y] = getline('closed');
    mask = poly2mask(x,y,size(im,1),size(im,2));
end

function phi = initialise(mask)
    dist=-bwdist(mask) + .5;
    dist2=bwdist(1 - mask) - .5;
    dist(mask) = dist2(mask);
    
    phi = dist;
end

function curv = curvature(phi)
    
    gX = convn(phi, [-1 0 1]/2, 'same');
    gY = convn(phi, [-1;0;1]/2, 'same');
    gXX = convn(phi, [-1 2 -1]/4, 'same');
    gYY = convn(phi, [-1;2;-1]/4, 'same');
    gXY = convn(phi, [-1 0 1; 0 0 0; 1 0 -1]./4, 'same');
    
    modgrad = ( gX.^2 + gY.^2 );
    curv = ( gXX .* gY.^2 + gYY .* gX.^2 - 2 * gX .* gY .* gXY ) ./ ( modgrad .^ (3/2) + .01 ) ;
end

function phi2 = re_initialise(phi)
    phi=interpn(phi,2);
    mask_ini = (phi>0);
    dist=-bwdist(mask_ini)+.5;
    dist2=bwdist(1-mask_ini)-.5;
    dist(mask_ini)=dist2(mask_ini);
    
    [x2,y2]=ndgrid(1:4:size(phi,1), 1:4:size(phi,2));
    phi2 = interpn(dist,x2,y2);
end

function gaussian_image = GaussianFilter(unfiltered_image, sigma)
    % 2D Gaussian filter
    
    % Shift the image so zero is the minimum, because the convolution uses
    % zero-padding
    intensity_offset = min(unfiltered_image(:));
    unfiltered_image = unfiltered_image - intensity_offset;
    
    resolution=[1 1];
    epsilon=1e-3;
    
    hsize = 2*max(ceil((sigma ./ resolution).*sqrt(-2*log(sqrt(2*pi).*(sigma ./ resolution)*epsilon)))) + 1;
    
    n = 1 : hsize;
    center = hsize/2 + 0.5;
    
    sigmax = sigma/resolution(1);
    sigmay = sigma/resolution(2);
    
    kerx = zeros(1,1,hsize);
    kery = zeros(1,1,hsize);
    
    kerx(1,1,:)=(1/((2*pi*sigmax.^2).^(1/2))) * exp(-((n-center).^2)/(2*sigmax.^2));
    kery(1,1,:)=(1/((2*pi*sigmay.^2).^(1/2))) * exp(-((n-center).^2)/(2*sigmay.^2));
    
    kerx = kerx./sum(kerx);
    kery = kery./sum(kery);
    
    gaussian_image = convn(convn(unfiltered_image, shiftdim(kerx, 2), 'same'), shiftdim(kery, 1), 'same');
    
    gaussian_image = gaussian_image + intensity_offset;
end