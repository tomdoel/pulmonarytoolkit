function threshold_image = PTKThresholdAirway(lung_image, use_wide_threshold)
    % Threshold a 3D volume with typical values for air
    %
    % This function performs a threshold operation which returns voxels
    % which lie within typical expected ranges for CT data, and for certain
    % MR data.
    %
    % Syntax:
    %     threshold_image = PTKThresholdAirway(lung_image, use_wide_threshold)
    %
    % Parameters:
    %     lung_image (PTKImage): the original image in a PTKImage class.
    %     use_wide_threshold: Provides a winder range of values for the
    %         threshold, which will better segment noisy images but may
    %         oversegment, e.g. airway walls.
    %
    % Returns:
    %     threshold_image is a binary PTKImage containing the voxels which
    %     lie within the threshold range.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if ~isa(lung_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end

    if lung_image.IsCT
        % CT voxels shouldn't have a value below -1024 but they sometimes
        % do...
        limit_1 = lung_image.RescaledToGreyscale(-1500);
        
        limit_2 = lung_image.RescaledToGreyscale(-775);
        
        % The wide threshold permits identification of other tissues within the
        % lung
        if exist('use_wide_threshold', 'var')
            if use_wide_threshold
                limit_2 = lung_image.RescaledToGreyscale(-400);
            end
        end
        
    else
        error('Unsupported modality');
    end
        
    raw_image = lung_image.RawImage;
    raw_image = (raw_image >= limit_1 & raw_image <= limit_2);
    
    threshold_image = lung_image.BlankCopy();
    threshold_image.ImageType = PTKImageType.Colormap;
    threshold_image.ChangeRawImage(raw_image);
end