function combined_image = TDCombineLeftAndRightImages(template, left, right, left_and_right_lungs)
    % TDCombineLeftAndRightImages. Combines images representing the left and
    %     right lungs. Typically this is used after image filtering has been
    %     separately performed on the two lungs to reduce memory usage.
    %
    %     Many examples of usage can be found in Toolkit plugins.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    combined_image = left.Copy;
    combined_image.ResizeToMatch(template);
    combined_raw_image = combined_image.RawImage;
    right_mask = left_and_right_lungs.RawImage == 1;
    left_mask = left_and_right_lungs.RawImage == 2;
    combined_raw_image(~left_mask) = 0;
    combined_image.Clear;
    combined_image.ChangeSubImage(right);
        
    combined_raw_image(right_mask) = combined_image.RawImage(right_mask);
    combined_image.ChangeRawImage(combined_raw_image);
end

