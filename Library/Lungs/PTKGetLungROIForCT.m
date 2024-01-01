function lung_image = PTKGetLungROIForCT(lung_image, reporting)
    % Find a region of interest from a chest CT image which contains the lungs and airways
    %
    % Syntax:
    %     lung_image = PTKGetLungROIForCT(lung_image, reporting);
    %
    % Arguments:
    %     lung_image (PTKImage): the full original lung volume stored as a PTKImage.
    %     reporting (CoreReportingInterface): an object for reporting progress and warnings
    %
    % Returns:
    %     lung_image (PTKImage): image cropped to the lung region of interest.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    if ~isa(lung_image, 'PTKImage')
        reporting.Error('PTKGetLungROIForCT:InputImageNotPTKImage', 'Requires a PTKImage as input');
    end

    if nargin < 2
        reporting = CoreReportingDefault();
    end
    
    reporting.ShowProgress('Rescaling image');
    
    reduced_image = lung_image.Copy;
    
    reduced_image.RescaleToMaxSize(128);

    reporting.ShowProgress('Filtering image');
    reduced_image = MimGaussianFilter(reduced_image, 1.0, true); % ToDo
    
    scale_factor = reduced_image.Scale;
    reporting.ShowProgress('Finding region of interest');
    reduced_image = PTKSegmentLungsWithoutClosing(reduced_image, false, true, false, reporting);
    
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
    
    reporting.CompleteProgress();
end
