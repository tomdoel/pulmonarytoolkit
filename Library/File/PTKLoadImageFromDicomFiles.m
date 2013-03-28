function loaded_image = PTKLoadImageFromDicomFiles(image_path, filenames, reporting)
    % PTKLoadImageFromDicomFiles. Loads a series of DICOM files into a 3D volume
    %
    %     Syntax
    %     ------
    %
    %         loaded_image = PTKLoadImageFromDicomFiles(path, filenames, reporting)
    %
    %             loaded_image    a PTKImage containing the 3D volume
    %
    %             path, filename  specify the location of the DICOM files to
    %                             load
    %
    %             reporting       A PTKReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting. If no
    %                             reporting object is specified then a default
    %                             reporting object with progress dialog is
    %                             created
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    % Create a reporting object if none was provided
    if nargin < 3
        reporting = PTKReportingDefault;
    end
    
    % Load the metadata from the DICOM images, and group into coherent sequences
    file_grouper = PTKLoadMetadataFromDicomFiles(image_path, filenames, reporting);
    
    % Warn the user if we found more than one group, since the others will not
    % be loaded into the image volume
    if file_grouper.NumberOfGroups > 1
        reporting.ShowWarning('PTKLoadImageFromDicomFiles:MultipleGroupings', 'I have removed some images from this dataset because the images did not form a coherent set. This may be due to the presence of scout images or dose reports, or localiser images in multiple orientations. I have formed a volume form the largest coherent set of images in the same orientation.');
    end
    
    % Choose the group with the most images
    main_group = file_grouper.GetLargestGroup;
    
    % Sort the images into the correct order
    [slice_thickness, global_origin_mm] = main_group.SortAndGetParameters(reporting);

    % Obtain a representative set of metadata tags from the first image in the
    % sequence
    representative_metadata = main_group.Metadata{1};

    % Load the pixel data
    image_volume_wrapper = PTKLoadImagesFromMetadataGrouping(main_group, reporting);
    
    % Detect and remove padding values
    PTKRemovePaddingValues(image_volume_wrapper, representative_metadata, reporting);
    
    % Construct a PTKDicomImage from the loaded image volume
    loaded_image = PTKDicomImage.CreateDicomImageFromMetadata(image_volume_wrapper, representative_metadata, slice_thickness, global_origin_mm, reporting);
    
end