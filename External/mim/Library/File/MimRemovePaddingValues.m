function new_padding_value = MimRemovePaddingValues(image_wrapper, metadata, reporting)
    % Remove padding voxels from an image 
    %
    % Padding voxels typically describe areas of an image that have no value because
    % they are outside of the scanning area. They may be assigned an artifical padding
    % value which indicates the voxel must be excluded from analysis.
    %
    % For visualisation and analysis purposes it is often simpler to replace the padding
    % values with a suitable background value that will not interfere with the visualisation
    % or analysis of the relevant regions. This function replaces padding voxels with the
    % lowest image internsity value minus one.
    %
    % Padding is determined by finding voxels equal to the PixelPaddingValue DICOM tag.
    % In addition, for GE scanners, voxels with values -2000 are also assumed to be padding 
    %
    % Syntax:
    %     new_padding_value = MimRemovePaddingValues(image_wrapper, metadata, reporting);
    %
    % Parameters:
    %     image_wrapper: image wrapper such as a CoreWrapper or PTKImage
    %     metadata: dictionary containing image metadata, including PixelPaddingValue and
    %         Manufacturer where present
    %     reporting (CoreReportingInterface): object
    %         for reporting progress and warnings
    %
    % Returns:
    %     is_supported: true if MIM supports this modality
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    new_padding_value = [];
    padding_indices = [];
    
    % Find padding voxels as defined by PixelPaddingValue tag
    if (isfield(metadata, 'PixelPaddingValue'))
        padding_value = metadata.PixelPaddingValue;
        
        padding_indices = find(image_wrapper.RawImage == padding_value);
    end
    
    % Check for unspecified padding value in GE images
    if isfield(metadata, 'Manufacturer')
        if strcmp(metadata.Manufacturer, 'GE MEDICAL SYSTEMS')
            padding_indices = find(image_wrapper.RawImage == -2000);
        end
    end

    % Replace padding value with the minimun image value - 1
    if ~isempty(padding_indices)
        image_wrapper.RawImage(padding_indices) = max(image_wrapper.RawImage(:));
        new_padding_value = min(image_wrapper.RawImage(:)) - 1;
        image_wrapper.RawImage(padding_indices) = new_padding_value;
    end
end
