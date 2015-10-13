function fileGrouper = DMImportRecursive(filenameOrRootDirectory, dicomLibrary, reporting)
    % DMImportRecursive. Loads metadata from a series of DICOM files
    %
    %     Syntax
    %     ------
    %
    %         file_grouper = DMLoadMetaDMImportRecursivedataFromDicomFiles(filenameOrRootDirectory, dicomLibrary, reporting)
    %
    %             file_grouper    a DMFileGrouper object containing the 
    %                             metadata grouped into coherent sequences of images
    %
    %             filenameOrRootDirectory specify the location of the DICOM
    %                             files.
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
    if nargin < 3 || isempty(reporting)
        reporting = CoreReportingDefault;
    end
    
    % Create a library object if none was provided
    if nargin < 2 || isempty(dicomLibrary)
        dicomLibrary = DMDicomLibrary.getLibrary;
    end
    
    % Show a progress dialog
    reporting.ShowProgress('Importing data');
    reporting.UpdateProgressValue(0);
    
    % The file grouper performs the sorting of image metadata
    fileGrouper = DMFileGrouper;
    
    dictionary = DMDicomDictionary.EssentialDictionaryWithoutPixelData;
    
    [importFolder, filenameOnly] = CoreDiskUtilities.GetFullFileParts(filenameOrRootDirectory);
    
    % Find out file type. 0=does not exist; 2=file; 7=directory
    exist_result = exist(filenameOrRootDirectory, 'file');
    
    if exist_result == 7
        % For a directory, we import every file
        ImportDirectoryRecursive(fileGrouper, dicomLibrary, importFolder, dictionary, reporting);
        
    elseif exist_result == 2
        % For a single file, we check if it is Dicom.
        if dicomLibrary.isdicom(filenameOrRootDirectory)
            % For a Dicom file we import the whole folder
            ImportDirectoryRecursive(fileGrouper, dicomLibrary, importFolder, dictionary, reporting);
        else
            % If this is not a Dicom image we exclude it from the set and warn the user
            reporting.ShowWarning('DMImportRecursive:NotADicomFile', ['The file ' filenameOrRootDirectory ' is not a DICOM file and will be removed from this series.']);
        end
        
    else
        reporting.Error('DMImportRecursive:FileDoesNotExist', ['The file or directory ' filenameOrRootDirectory ' does not exist.']);
    end
    
    reporting.CompleteProgress;
end

function ImportDirectoryRecursive(fileGrouper, dicomLibrary, directory, dictionary, reporting)
    directories_to_do = CoreStack(directory);
    
    while ~directories_to_do.IsEmpty
        current_dir = directories_to_do.Pop;
        
        reporting.UpdateProgressMessage(['Importing data from: ' current_dir]);
        
        if reporting.HasBeenCancelled
            reporting.Error(CoreReporting.CancelErrorId, 'User cancelled');
        end
        
        ImportFilesInDirectory(fileGrouper, dicomLibrary, current_dir, dictionary, reporting);
        next_dirs = CoreDiskUtilities.GetListOfDirectories(current_dir);
        for dir_to_add = next_dirs
            new_dir = fullfile(current_dir, dir_to_add{1});
            directories_to_do.Push(new_dir);
        end
    end
end

function ImportFilesInDirectory(fileGrouper, dicomLibrary, directory, dictionary, reporting)
    all_filenames = CoreTextUtilities.SortFilenames(CoreDiskUtilities.GetDirectoryFileList(directory, '*'));
    for filename = all_filenames
        fullFileName = fullfile(directory, filename{1});
        if ~strcmp(fullFileName, 'DICOMDIR')
            try
                if dicomLibrary.isdicom(fullFileName)
                    fileGrouper.AddFile(dicomLibrary.dicominfo(fullFileName, dictionary));
                else
                    % If this is not a Dicom image we exclude it from the set and warn the user
                    reporting.ShowWarning('DMImportRecursive:NotADicomFile', ['DMLoadMetadataFromDicomFiles: The file ' fullFileName ' is not a DICOM file and will be removed from this series.']);
                end
            catch ex
                reporting.ShowWarning('DMImportRecursive:ImportFileFailed', ['Failed to import file ' fullFileName ' due to error: ' ex.message]);
            end
        end
    end
end