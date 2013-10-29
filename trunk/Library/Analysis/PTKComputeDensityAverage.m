function [density_average, density_values_computed_mask, density_valid_values_mask] = PTKComputeDensityAverage(lung_roi, mask, non_parenchyma_voxels, reporting)
    % PTKComputeDensityAverage. Computes the density of parenchymal tissue by averaging over neighbouring voxels
    %
    % Given a DICOM lung image, returns the density of voxels in the lung
    % parenchyma, averaged over a 5x5x5 voxel neighbourgood. Voxels close to the
    % image boundaries and in the airways are excluded.
    %
    %
    % Inputs:
    %     lung_roi - a PTKImage containing the raw image values
    %
    %     mask - a PTKImage mask containing the voxels inside the lung
    %
    %     reporting (optional) - an object implementing the PTKReporting
    %         interface for reporting progress and warnings
    %
    % Outputs:
    %     density_average - a PTKImage containing average density values in g/mL
    %
    %     density_average_mask - a PTKImage containing a mask of voxels whose
    %         densities were calculated
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    if ~isa(lung_roi, 'PTKImage') || ~isa(mask, 'PTKImage') || ~isa(non_parenchyma_voxels, 'PTKImage')
        reporting.Error('PTKComputeDensityAverage:InvalidInput', 'Requires a PTKImage for all inputs');
    end
    
    if nargin < 4
        reporting = PTKReportingDefault;
    end
    
    % Compute the density at each voxel
    reporting.ShowProgress('Computing average lung density');
    density_g_mL_image = PTKConvertCTToDensity(lung_roi);
    
    % The neighbourhood used to compute the density is a structural element
    density_average_el = ones(7,7,7);
    size_el = numel(density_average_el);
    
    % Create a mask of the lung parenchyma
    lung_mask = mask.BlankCopy;
    lung_mask.ChangeRawImage(mask.RawImage > 0);
    
    % Create a mask of valid density values to be used in the calculation
    % These are points in the parenchyma excluding the points specified by the
    % non_parenchyma_voxels mask
    density_valid_values_mask = lung_mask.BlankCopy;
    density_valid_values_mask.ChangeRawImage(lung_mask.RawImage & ~non_parenchyma_voxels.RawImage);
    
    % Remove the lung exterior and non-parenchyma points from the density image. We
    % do this so they don't contribute to the sum used to compute the density
    % average
    density_g_mL_image.ChangeRawImage(density_g_mL_image.RawImage.*double(density_valid_values_mask.RawImage));

    % Average the mask, in order to determine how many neighbouring voxels
    % contribute towards the density average of each voxel
    reporting.ShowProgress('Computing scaling factor');
    number_of_contributing_voxels = convn(single(density_valid_values_mask.RawImage), density_average_el, 'same');
    
    % To prevent divide by zero errors, find points with zero neighbours and set
    % the divisor to 1 (we will fix their values later)
    zero_mask = number_of_contributing_voxels == 0;
    number_of_contributing_voxels(zero_mask) = 1;

    % Average the density over the neighbourhood
    density_average_raw = convn(density_g_mL_image.RawImage, density_average_el, 'same')./number_of_contributing_voxels;

    % Find voxels with invalid density values - those in the non-parenchyma mask, or those with
    % more than half of their neighbours outside of the lung mask
    points_to_fix = lung_mask.RawImage & ((number_of_contributing_voxels < ceil(size_el/2)) | non_parenchyma_voxels.RawImage);
    
    % Valid points are all the rest in the lung mask
    points_ok = (~points_to_fix) & lung_mask.RawImage;
    
    % Find the indices of the nearest neighbours for these points
    [~, nn_index] = bwdist(points_ok);
    
    % Replace the density values with that from the nearest neighbour
    density_average_raw(points_to_fix) = density_average_raw(nn_index(points_to_fix));
    
    density_average_raw(~mask.RawImage) = 0;
    
    density_values_computed_mask = mask.Copy;
    
    reporting.ShowProgress('Storing results');
    density_average = lung_roi.BlankCopy;
    density_average.ChangeRawImage(density_average_raw);
    density_average.ImageType = PTKImageType.Scaled;
end