function image = MimLoadImages(image_info, reporting)
    % Load images specified in a PTKImageInfo structure
    %
    % Syntax:
    %     image = MimLoadImages(image_info, reporting);
    %
    % Parameters:
    %     image_info: PTKImageInfo struture defining the images to load
    %     reporting (CoreReportingInterface): object for reporting 
    %         progress and warnings
    %
    % Returns:
    %     image: PTKImage object containing data from the loaded series
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    image_path = image_info.ImagePath;
    filenames = image_info.ImageFilenames;
    image_file_format = image_info.ImageFileFormat;
    study_uid = image_info.StudyUid;
    
    if isempty(filenames)
        filenames = CoreDiskUtilities.GetDirectoryFileList(image_path, '*');
        if isempty(filenames)
            reporting.Error(MimErrors.FileMissingErrorId, ['Cannot find any files in the folder ' image_path]);
        end
    else
        first_file = filenames{1};
        if isa(first_file, 'CoreFilename')
            first_file_path = first_file.Path;
            first_file_name = first_file.Name;
        else
            first_file_path = image_path;
            first_file_name = first_file;
        end
        if ~CoreDiskUtilities.FileExists(first_file_path, first_file_name)
            reporting.Error(MimErrors.FileMissingErrorId, ['Cannot find the file ' fullfile(image_path, first_file_name)]);
        end
    end
    
    if isempty(image_file_format)
        reporting.Error(MimErrors.FileFormatUnknownErrorId, 'Could not load the image because the file format was not recognised.');
    else
        switch image_file_format
            case MimImageFileFormat.Dicom
                image = MimLoadImageFromDicomFiles(image_path, filenames, reporting);
            case MimImageFileFormat.Metaheader
                image = MimLoad3DRawAndMetaFiles(image_path, filenames, study_uid, reporting);
            case {MimImageFileFormat.Analyze, MimImageFileFormat.Gipl, ...
                    MimImageFileFormat.Isi, MimImageFileFormat.Nifti, MimImageFileFormat.V3d, ...
                    MimImageFileFormat.Vmp, MimImageFileFormat.Xif, MimImageFileFormat.Vtk, ...        % Visualization Toolkit (VTK)
                    MimImageFileFormat.MicroCT, MimImageFileFormat.Par}
                image = MimLoadOtherFormat(image_path, filenames, study_uid, image_file_format, reporting);
            otherwise
                reporting.Error('MimLoadImages:UnknownImageFileFormat', 'Could not load the image because the file format was not recognised.');
        end
    end
end
