function [imageWrapper, representativeMetadata, sliceThickness, globalOriginMm] = DMLoadMainImageFromDicomFiles(imagePath, filenames, dicomLibrary, reporting)
    % DMLoadImageFromDicomFiles Loads a series of DICOM files into a coherent 3D volume.
    %
    % DMLoadImageFromDicomFiles parses the Dicom files and groups them into
    % coherent image volumes. The largest image volume is returned as a 3D
    % image volume in a CoreWrapper object.
    %
    %     Syntax
    %     ------
    %
    %         imageWrapper = DMLoadMainImageFromDicomFiles(path, filenames, dicomLibrary, reporting)
    %
    %             imageWrapper    a CoreWrapper containing the 3D volume
    %
    %             representativeMetadata  metadata from one slice of the main group
    %
    %             sliceThickness the computed distance between
    %                             centrepoints of each slice
    %
    %             globalOriginMm  The mm coordinates of the image origin
    %
    %             path, filename  specify the location of the DICOM files to
    %                             load
    %
    %             dicomLibrary    (Optional) An object implementing
    %                             DMDicomLibraryInterface, used to parse
    %                             the Dicom files. If no object is provided
    %                             then the default DMDicomLibrary is used
    %
    %             reporting       (Optional) An object implementing
    %                             CoreReportingInterface for error, warning
    %                             and progress reporting. If no object is
    %                             provided then a default reporting object
    %                             is created.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    % Create a reporting object if none was provided
    if nargin < 4 || isempty(reporting)
        reporting = CoreReportingDefault;
    end
    
    % Create a library object if none was provided
    if nargin < 3 || isempty(dicomLibrary)
        dicomLibrary = DMDicomLibrary.getLibrary;
    end
    
    % Load the metadata from the DICOM images, and group into coherent sequences
    fileGrouper = DMLoadMetadataFromDicomFiles(imagePath, filenames, dicomLibrary, reporting);
    
    % Warn the user if we found more than one group, since the others will not
    % be loaded into the image volume
    if fileGrouper.NumberOfGroups > 1
        reporting.ShowWarning('DMLoadMainImageFromDicomFiles:MultipleGroupings', 'I have removed some images from this dataset because the images did not form a coherent set. This may be due to the presence of scout images or dose reports, or localiser images in multiple orientations. I have formed a volume form the largest coherent set of images in the same orientation.');
    end
    
    % Choose the group with the most images
    main_group = fileGrouper.GetLargestGroup;
    
    % Sort the images into the correct order
    [sliceThickness, globalOriginMm] = main_group.SortAndGetParameters(reporting);

    % Obtain a representative set of metadata tags from the first image in the
    % sequence
    representativeMetadata = main_group.Metadata{1};

    % Load the pixel data
    imageWrapper = DMLoadImagesFromMetadataGrouping(main_group, dicomLibrary, reporting);
end