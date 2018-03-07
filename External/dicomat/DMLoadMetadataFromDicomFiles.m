function file_grouper = DMLoadMetadataFromDicomFiles(image_path, filenames, dicomLibrary, reporting)
    % DMLoadMetadataFromDicomFiles. Loads metadata from a series of DICOM files
    %
    %     Syntax
    %     ------
    %
    %         file_grouper = DMLoadMetadataFromDicomFiles(path, filenames, reporting)
    %
    %             file_grouper    a DMFileGrouper object containing the 
    %                             metadata grouped into coherent sequences of images
    %
    %             image_path, filenames specify the location of the DICOM
    %                             files. filenames can be a string for a
    %                             single filename, or a cell array of
    %                             strings
    %
    %             dicomLibrary    (Optional) An object implementing
    %                             DMDicomLibraryInterface, used to parse
    %                             the Dicom files. If no object is provided
    %                             then the default DMDicomLibrary is used
    %
    %             reporting       A CoreReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a CoreReporting
    %                             with no arguments to hide all reporting. If no
    %                             reporting object is specified then a default
    %                             reporting object with progress dialog is
    %                             created
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %        

    % Create a reporting object if none was provided
    if nargin < 4 || isempty(reporting)
        reporting = CoreReportingDefault;
    end
    
    % Create a library object if none was provided
    if nargin < 3 || isempty(dicomLibrary)
        dicomLibrary = DMDicomLibrary.getLibrary;
    end
    
    % Show a progress dialog
    reporting.ShowProgress('Reading image metadata');
    reporting.UpdateProgressValue(0);
    
    % A single filename canbe specified as a string
    if ischar(filenames)
        filenames = {filenames};
    end
    
    % Sort the filenames into numerical order. Normally, this ordering will be
    % overruled by the ImagePositionPatient or SliceLocation tags, but in the
    % absence of other information, the numerical slice ordering will be used.
    sorted_filenames = CoreTextUtilities.SortFilenames(filenames);
    num_slices = length(filenames);
    
    % The file grouper performs the sorting of image metadata
    file_grouper = DMFileGrouper;
    
    dictionary = DMDicomDictionary.EssentialDictionaryWithoutPixelData;
    
    for file_index = 1 : num_slices
        next_file = sorted_filenames{file_index};
        if isa(next_file, 'CoreFilename')
            file_path = next_file.Path;
            file_name = next_file.Name;
        else
            file_path = image_path;
            file_name = next_file;
        end
        
        if dicomLibrary.isdicom(fullfile(file_path, file_name))
            file_grouper.AddFile(dicomLibrary.dicominfo(fullfile(file_path, file_name), dictionary));
        else
            % If this is not a Dicom image we exclude it from the set and warn the user
            reporting.ShowWarning('DMLoadMetadataFromDicomFiles:NotADicomFile', ['DMLoadMetadataFromDicomFiles: The file ' fullfile(file_path, file_name) ' is not a DICOM file and will be removed from this series.']);
        end
        
        reporting.UpdateProgressValue(round(100*file_index/num_slices));
        
    end

    reporting.CompleteProgress;
end