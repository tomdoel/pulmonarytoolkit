function file_grouper = PTKLoadMetadataFromDicomFiles(image_path, filenames, reporting)
    % PTKLoadMetadataFromDicomFiles. Loads metadata from a series of DICOM files
    %
    %     Syntax
    %     ------
    %
    %         file_grouper = PTKLoadMetadataFromDicomFiles(path, filenames, reporting)
    %
    %             file_grouper    a PTKFileGrouper object containing the 
    %                             metadata grouped into coherent sequences of images
    %
    %             image_path, filenames specify the location of the DICOM
    %                             files.
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

    if nargin < 3
        reporting = PTKReportingDefault;
    end
    
    % Show a progress dialog
    reporting.ShowProgress('Loading image metadata');
    reporting.UpdateProgressValue(0);
    
    % Sort the filenames into numerical order. Normally, this ordering will be
    % overruled by the ImagePositionPatient or SliceLocation tags, but in the
    % absence of other information, the numerical slice ordering will be used.
    sorted_filenames = PTKTextUtilities.SortFilenames(filenames);
    num_slices = length(filenames);
    
    % The file grouper performs the sorting of image metadata
    file_grouper = PTKFileGrouper;
    
    for file_index = 1 : num_slices
        
        if PTKDicomUtilities.PTKIsDicom(image_path, sorted_filenames{file_index})
            file_grouper.AddFile(PTKDicomUtilities.ReadMetadata(image_path, sorted_filenames{file_index}, reporting));
        else
            % If this is not a Dicom image we exclude it from the set and warn the
            % user
            reporting.ShowWarning('PTKLoadMetadataFromDicomFiles:NotADicomFile', ['PTKLoadMetadataFromDicomFiles: The file ' file_name ' is not a DICOM file and will be removed from this series.']);
        end
        
        reporting.UpdateProgressValue(round(100*file_index/num_slices));
        
    end

    reporting.CompleteProgress;
end