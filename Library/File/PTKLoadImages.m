function image = PTKLoadImages(image_info, reporting)
    % PTKLoadImages.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
                image = PTKLoadImageFromDicomFiles(image_path, filenames, reporting);
            case MimImageFileFormat.Metaheader
                image = PTKLoad3DRawAndMetaFiles(image_path, filenames, study_uid, reporting);
            case {MimImageFileFormat.Analyze, MimImageFileFormat.Gipl, ...
                    MimImageFileFormat.Isi, MimImageFileFormat.Nifti, MimImageFileFormat.V3d, ...
                    MimImageFileFormat.Vmp, MimImageFileFormat.Xif, MimImageFileFormat.Vtk, ...        % Visualization Toolkit (VTK)
                    MimImageFileFormat.MicroCT, MimImageFileFormat.Par}
                image = PTKLoadOtherFormat(image_path, filenames, study_uid, image_file_format, reporting);
            otherwise
                reporting.Error('PTKOriginalImage:UnknownImageFileFormat', 'Could not load the image because the file format was not recognised.');
        end
    end
end