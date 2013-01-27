function [density_average, density_average_mask] = PTKComputeDensityAverage(lung_roi, mask, airways, reporting)
    % PTKComputeDensityAverage. Computes the density of parenchymal tissue by averaging over neighbouring voxels
    %
    % Given a DICOM lung image, returns the density of voxels in the lung
    % parenchyma, averaged over a 5x5x5 voxel neighbourgood. Voxels close to the
    % image boundaries and in the airways are excluded.
    %
    % Syntax:
    %     top_of_trachea = PTKFindTopOfTrachea(lung_image, reporting)
    %     [top_of_trachea, trachea_voxels] = PTKFindTopOfTrachea(lung_image, reporting)
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
    
    
    if ~isa(lung_roi, 'PTKImage') || ~isa(mask, 'PTKImage') || ~isa(airways, 'PTKImage')
        reporting.Error('PTKComputeDensityAverage:InvalidInput', 'Requires a PTKImage for all inputs');
    end
    
    if nargin < 4
        reporting = PTKReportingDefault;
    end
    
    % The neighbourhood used to compute the density is a structural element
    density_average_el = ones(5,5,5);
    size_el = numel(density_average_el);
    
    % Create a mask comprising of the lung exterior and the segmented airways
    reporting.ShowProgress('Creating a parenchyma mask excluding borders and airways');
    density_average_mask = mask.BlankCopy;
    density_average_mask.ChangeRawImage((mask.RawImage == 0) | (airways.RawImage == 1));
    
    % Expand mask to include neighbouring voxels
    density_average_mask.BinaryMorph(@imdilate, 3);
    
    % Invert mask so it now represents the lung parenchyma
    density_average_mask.ChangeRawImage(~density_average_mask.RawImage);
    
    % Remove the mask from the lung image
    lung_roi = lung_roi.Copy;
    lung_roi.ChangeRawImage(int16(lung_roi.RawImage).*int16(density_average_mask.RawImage));
    
    % Average the mask, in order to determine how many neighbouring voxels
    % contribute towards the density average of each voxel
    reporting.ShowProgress('Computing scaling factor');
    number_of_contributing_voxels = convn(single(density_average_mask.RawImage), density_average_el, 'same');
    
    % Compute the density at each voxel
    reporting.ShowProgress('Computing average lung density');
    density_g_mL_image = PTKConvertCTToDensity(lung_roi);
    
    % To prevent divide by zero errors
    zero_mask = number_of_contributing_voxels == 0;
    number_of_contributing_voxels(zero_mask) = 1;

    % Average the density over the neighbourhood
    density_average_raw = convn(density_g_mL_image.RawImage, density_average_el, 'same')./number_of_contributing_voxels;
    
    % Exclude voxels with more than half of their voxels outside of the lung mask
    too_few_neighbours = number_of_contributing_voxels < ceil(size_el/2);
    density_average_mask.ChangeRawImage((density_average_mask.RawImage) & (~too_few_neighbours));
    density_average_raw(~density_average_mask.RawImage) = 0;
        
    reporting.ShowProgress('Storing results');
    density_average = lung_roi.BlankCopy;
    density_average.ChangeRawImage(density_average_raw);
    density_average.ImageType = PTKImageType.Scaled;
end