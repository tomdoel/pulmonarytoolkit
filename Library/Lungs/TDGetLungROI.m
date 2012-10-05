function lung_image = TDGetLungROI(lung_image, reporting)
    % TDGetLungROI. Finds a region of interest from a chest CT image which
    %     contains the lungs and airways
    %
    %     Inputs
    %     ------
    %
    %     lung_image - the full original lung volume stored as a TDImage.
    %
    %     reporting (optional) - an object implementing the TDReporting
    %         interface for reporting progress and warnings
    %
    %
    %     Outputs
    %     -------
    %
    %     lung_image - a TDImage cropped to the lung region of interest.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    if ~isa(lung_image, 'TDImage')
        error('Requires a TDImage as input');
    end

    if nargin < 2
        reporting = TDReportingDefault;
    end
    
    reporting.ShowProgress('Rescaling image');
    
    reduced_image = lung_image.Copy;
    
    reduced_image.RescaleToMaxSize(128);

    reporting.ShowProgress('Filtering image');
    reduced_image = TDGaussianFilter(reduced_image, 1.0);
    
    scale_factor = reduced_image.Scale;
    reporting.ShowProgress('Finding region of interest');
    reduced_image = TDSegmentLungsWithoutClosing(reduced_image, false, true, reporting);
    
    % Use the crop function to find the offset and image size
    original_origin = reduced_image.Origin;
    reduced_image.CropToFit;
    offset = reduced_image.Origin - original_origin;
    
    % Scale back to normal size, allowing a border
    new_size = scale_factor.*(reduced_image.ImageSize + [4 4 4]);
    start_crop = scale_factor.*(offset  - [2 2 2]);
    end_crop = start_crop + new_size;
    start_crop = max(start_crop, [1 1 1]);
    end_crop = min(end_crop, lung_image.ImageSize);
    
    reporting.ShowProgress('Cropping image');    
    lung_image = lung_image.Copy;
    lung_image.Crop(start_crop, end_crop);
    
    reporting.CompleteProgress;
end
