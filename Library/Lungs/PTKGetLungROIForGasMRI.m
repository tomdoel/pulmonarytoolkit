function lung_image = PTKGetLungROIForGasMRI(lung_image, reporting)
    % PTKGetLungROIForGasMRI. Finds a region of interest from a chest gas MRI
    %     ventilation image which contains the lungs and airways
    %
    %     Inputs
    %     ------
    %
    %     lung_image - the full original lung volume stored as a PTKImage.
    %
    %     reporting (optional) - an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Outputs
    %     -------
    %
    %     lung_image - a PTKImage cropped to the lung region of interest.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    if ~isa(lung_image, 'PTKImage')
        reporting.Error('PTKGetLungROIForGasMRI:InputImageNotPTKImage', 'Requires a PTKImage as input');
    end
    
    if nargin < 2
        reporting = CoreReportingDefault;
    end

    reporting.ShowProgress('Finding region of interest');

    % Filter image
    lung_threshold = MimGaussianFilter(lung_image, 2);
    
    % Threshold
    lung_threshold.ChangeRawImage(lung_threshold.RawImage > 2);
    
    % Extract out the main region
    lung_threshold.AddBorder(1);
    lung_threshold = PTKGetMainRegionExcludingBorder(lung_threshold, 1000000, reporting);
    lung_threshold.RemoveBorder(1);
    
    % Crop the original image to the main region of the threshold image
    lung_threshold.CropToFitWithBorder(5);
    lung_image.ResizeToMatch(lung_threshold);
    
    reporting.CompleteProgress;
end
