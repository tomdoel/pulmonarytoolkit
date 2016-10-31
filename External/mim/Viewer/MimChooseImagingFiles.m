function image_info = MimChooseImagingFiles(image_path, reporting)
    % MimChooseImagingFiles. Displays a dialog for choosing image files to load.
    %
    %     This function displays a dialog which allows users to select medical
    %     imaging files to load. The function returns a MimImageInfo structure
    %     which contains the filenames and paths. If a DICOM file is selected,
    %     then all matching files in that directory will be selected.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    filespec = {
        '*;*.*', 'All files (*.*)';
        '*;*.*', 'DICOM files (*.*)';
        '*.mhd;*.mha', 'Metaheader and raw data (*.mhd,*.mha)';
        '*.hdr;*.img', 'Analyze';
        '*.gipl', 'Guys Image Processing Lab';
        '*.isi', 'ISI';
        '*.nii', 'NIFTI';
        '*.v3d', 'Philips V3D';
        '*.vmp', 'BrainVoyager';
        '*.xif', 'HDllab/ATL Ultrasound';
        '*.vtk', 'Visualization Toolkit (VTK)';
        '*.vff', 'MicroCT';
        '*.par;*.rec', 'Philips PAR/REC'
        };

    [image_path, filenames, filter_index] = CoreDiskUtilities.ChooseFiles('Select the file to import', image_path, true, filespec);
    
    if isempty(image_path)
        image_info = [];
        return
    end
    
    % If in DICOM format, then we will load the entire directory
    if (filter_index ==  2)
        filenames_dicom = CoreTextUtilities.SortFilenames(CoreDiskUtilities.GetDirectoryFileList(image_path, '*'));
        filenames_dicom = DMUtilities.RemoveNonDicomFiles(image_path, filenames_dicom);
        image_type = MimImageFileFormat.Dicom;
        
        % If there are no valid DICOM files then we return an ImageInfo with
        % just the path and image type set
        if isempty(filenames_dicom)
            image_info = MimImageInfo(image_path, [], image_type, [], [], []);
            return;
        end
        image_info = MimImageInfo(image_path, filenames_dicom, image_type, [], [], []);
        return;
        
    elseif (filter_index == 3)
        image_type = MimImageFileFormat.Metaheader;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 4)
        image_type = MimImageFileFormat.Analyze;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 5)
        image_type = MimImageFileFormat.Gipl;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 6)
        image_type = MimImageFileFormat.Isi;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 7)
        image_type = MimImageFileFormat.Nifti;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 8)
        image_type = MimImageFileFormat.V3d;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 9)
        image_type = MimImageFileFormat.Vmp;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 10)
        image_type = MimImageFileFormat.Xif;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 11)
        image_type = MimImageFileFormat.Vtk;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 13)
        image_type = MimImageFileFormat.MicroCT;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;

    elseif (filter_index == 13)
        image_type = MimImageFileFormat.Par;
        image_info = MimImageInfo(image_path, {filenames{1}}, image_type, [], [], []);
        return;
    end
    
    % No format specified, so we try to infer from the file itself
    [image_type, principal_filename, secondary_filenames] = MimGuessFileType(image_path, filenames{1}, [], reporting);
    filenames = principal_filename;
    
    % If in DICOM format, then we will load the entire directory
    if (image_type == MimImageFileFormat.Dicom)
        filenames = CoreTextUtilities.SortFilenames(CoreDiskUtilities.GetDirectoryFileList(image_path, '*'));
        filenames = DMUtilities.RemoveNonDicomFiles(image_path, filenames);
        
        % If there are no valid DICOM files then we return an ImageInfo with
        % just the path and image type set
        if isempty(filenames)
            image_info = MimImageInfo(image_path, [], image_type, [], [], []);
            return;
        end
    end

    image_info = MimImageInfo(image_path, filenames, image_type, [], [], []);
end


