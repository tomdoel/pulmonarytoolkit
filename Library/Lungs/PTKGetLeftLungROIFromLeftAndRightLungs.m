function lung_roi = TDGetLeftLungROIFromLeftAndRightLungs(lung_image, left_and_right_lung_mask, reporting)
    % TDGetLeftLungROIFromLeftAndRightLungs. Extracts a region of interest for the left lung given the original image and the left and right lung mask.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    mask = left_and_right_lung_mask.Copy;
    mask.ChangeRawImage(uint8(mask.RawImage == 2));
    mask.CropToFitWithBorder(5);
    lung_roi = lung_image.Copy;
    lung_roi.ResizeToMatch(mask);
end

