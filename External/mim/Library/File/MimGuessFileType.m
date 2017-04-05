function [image_type, principal_filename, secondary_filenames] = MimGuessFileType(file_path, image_filename, default_guess, reporting)
    % MimGuessFileType. Heuristically determines a file format
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    [~, name, ext] = fileparts(image_filename);
    image_filename_without_extension = fullfile(file_path, name);
    if strcmp(ext, '.mat')
        image_type = MimImageFileFormat.Matlab;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.gipl')
        image_type = MimImageFileFormat.Gipl;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.hdr')
        image_type = MimImageFileFormat.Analyze;
        principal_filename = {image_filename};
        secondary_filenames = {};
        if CoreDiskUtilities.FileExists(file_path, [name '.img'])
            secondary_filenames = [image_filename_without_extension '.img'];
        end
        return;

    elseif strcmp(ext, '.nii')
        image_type = MimImageFileFormat.Nifti;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.img')
        hdr_filename = [name '.hdr'];
        nii_filename = [name '.nii'];
        if CoreDiskUtilities.FileExists(file_path, nii_filename)
            image_type = MimImageFileFormat.Nifti;
            principal_filename = {fullfile(file_path, nii_filename)};
            secondary_filenames = {image_filename};
            return;
        elseif CoreDiskUtilities.FileExists(file_path, hdr_filename)
            image_type = MimImageFileFormat.Analyze;
            principal_filename = {fullfile(file_path, hdr_filename)};
            secondary_filenames = {image_filename};
            return;
        end

    elseif strcmp(ext, '.isi')
        image_type = MimImageFileFormat.Isi;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.v3d')
        image_type = MimImageFileFormat.V3d;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.vmp')
        image_type = MimImageFileFormat.Vmp;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.xif')
        image_type = MimImageFileFormat.Xif;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.vtk')
        image_type = MimImageFileFormat.Vtk;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.vff')
        image_type = MimImageFileFormat.MicroCT;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;

    elseif strcmp(ext, '.par') || strcmp(ext, '.rec')
        image_type = MimImageFileFormat.Par;
        par_filename = {[name '.par']};
        rec_filename = {[name '.rec']};
        par_found = CoreDiskUtilities.FileExists(file_path, par_filename);
        rec_found = CoreDiskUtilities.FileExists(file_path, rec_filename);
        if par_found
            if rec_found
                principal_filename = {fullfile(file_path, par_filename)};
                secondary_filenames = {fullfile(file_path, rec_filename)};
                return;
            else
                principal_filename = {fullfile(file_path, par_filename)};
                secondary_filenames = {};
                return;
            end
        else
            if rec_found
                principal_filename = {rec_filename};
                secondary_filenames = {};
                return;
            end
        end


    % For metaheader files (mhd/mha) we also fetch the filename of the
    % raw image data
    elseif strcmp(ext, '.mhd') || strcmp(ext, '.mha')
        image_type = MimImageFileFormat.Metaheader;
        [is_meta_header, raw_filename] = MimDiskUtilities.IsFileMetaHeader(fullfile(image_path, image_filename), reporting);
        if ~is_meta_header
            reporting.Error('MimGuessFileType:OpenMHDFileFailed', ['Unable to read metaheader file ' image_filename]);
        end
        principal_filename = {image_filename};
        secondary_filenames = {raw_filename}; % ToDo: what if no secondary file?
        return;

    % If a .raw file is selected, look for the corresponding .mha or
    % .mhd file. We thrown an exception if no file is found, it cannot
    % be loaded or the raw filename does not match the raw file we are
    % loading
    elseif strcmp(ext, '.raw')
        [principal_filename, secondary_filenames] = MimDiskUtilities.GetHeaderFileFromRawFile(image_path, name, reporting);
        if isempty(principal_filename)
            reporting.ShowWarning('MimGuessFileType:HeaderFileLoadError', ['Unable to find valid header file for ' fullfile(image_path, image_filename)], []);
        else
            if ~strcmp(secondary_filenames{1}, image_filename)
                reporting.Error('MimGuessFileType:MetaHeaderRawFileMismatch', ['Mismatch between specified image filename and entry in ' principal_filename{1}]);
            end
            image_type = MimImageFileFormat.Metaheader;
            return;
        end
    end

    % Unknown file type. Try looking for a header file
    [principal_filename_mh, secondary_filenames_mh] = MimDiskUtilities.GetHeaderFileFromRawFile(image_path, name, reporting);
    if (~isempty(principal_filename_mh)) && (strcmp(secondary_filenames_mh{1}, image_filename))
        image_type = MimImageFileFormat.Metaheader;
        principal_filename = principal_filename_mh;
        secondary_filenames = secondary_filenames_mh;
        return;
    end

    % Test for a DICOM image
    if DMUtilities.IsDicom(image_path, image_filename)
        image_type = MimImageFileFormat.Dicom;
        principal_filename = {image_filename};
        secondary_filenames = {};
        return;
    end

    % If all else fails, use the guess
    image_type = default_guess;
    principal_filename = {image_filename};
    secondary_filenames = {};
end

