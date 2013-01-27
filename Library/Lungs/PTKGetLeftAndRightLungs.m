function results = PTKGetLeftAndRightLungs(unclosed_lungs, filtered_threshold_lung, lung_roi, reporting)
    % PTKGetLeftAndRightLungs. Extracts left and right lungs from a lung
    %     segmentation, with morphological smoothing and hole-flling
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    
    results = PTKSeparateAndLabelLungs(unclosed_lungs, filtered_threshold_lung, lung_roi, reporting);
    
    reporting.UpdateProgressAndMessage(25, 'Closing right lung');
    right_lung = results.Copy;
    right_lung.ChangeRawImage(right_lung.RawImage == 1);
    right_lung.CropToFit;
    
    if PTKSoftwareInfo.FastMode
        close_size = 5;
    else
        close_size = 8;
    end
    
    % Perform morphological closing with a spherical structure element of radius 8mm
    right_lung.MorphWithBorder(@imclose, close_size);
    
    % Fill any remaining holes inside the 3D image
    right_lung = PTKFillHolesInImage(right_lung);
    
    right_lung.ChangeRawImage(uint8(right_lung.RawImage));
    
    reporting.UpdateProgressAndMessage(50, 'Closing left lung');
    left_lung = results.Copy;
    left_lung.ChangeRawImage(left_lung.RawImage == 2);
    left_lung.CropToFit;
    
    % Perform morphological closing with a spherical structure element of radius 8mm
    left_lung.MorphWithBorder(@imclose, close_size);
    % Fill any remaining holes inside the 3D image
    left_lung = PTKFillHolesInImage(left_lung);
    
    left_lung.ChangeRawImage(2*uint8(left_lung.RawImage));
    
    reporting.UpdateProgressAndMessage(75, 'Combining');
    
    results.Clear;
    results.ChangeSubImage(left_lung);
    results2 = results.Copy;
    results2.Clear;
    results2.ChangeSubImage(right_lung);
    results.ChangeRawImage(min(2, results.RawImage + results2.RawImage));
    results.ImageType = PTKImageType.Colormap;
end

