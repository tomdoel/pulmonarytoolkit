function MimSaveAsNifti(image_to_save, path, filename, reporting, orientinfo)
    % MimSaveAsNifti. Writes out a PTKImage in NIFTI format
    %
    %     Syntax
    %     ------
    %
    %         MimSaveAsNifti(image_data, path, filename, data_type, orientation, reporting)
    %
    %             image_to_save   is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved
    %             path, filename  specify the location to save the NIFTI data.
    %             reporting       an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        
    
    if nargin < 4
        reporting = CoreReportingDefault();
    end
    
    if ~isa(image_to_save, 'PTKImage')
        reporting.Error('MimSaveAsNifti:InputMustBePTKImage', 'Requires a PTKImage as input');
    end

    image_data = image_to_save.RawImage;
    
    full_filename = fullfile(path, filename);

    resolution = image_to_save.VoxelSize([2, 1, 3]);
    
    try
        Gorig = image_to_save.GlobalOrigin;
        offset = [Gorig(2),Gorig(1),Gorig(3)];
    catch
        offset = [0 0 0];
    end
    
    if isa(image_data, 'PTKDicomImage')
        metadata = image_data. MetaHeader;
        if isfield(metadata, 'Offset')
            offset = metadata.Offset;
        end
    end
    
    % Goal: reverse the permutations and flips on the image data to its original.
    if exist('orientinfo','var')
        orientation = [orientinfo.affine4x4(1,1:3),orientinfo.affine4x4(2,1:3)];
        [permute_vec, flip_vec] = MimImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation(orientation, reporting);
        % ijk to xyz permutation first.
        image_data = permute(image_data, [2, 1, 3]);
        image_data = permute(image_data, permute_vec);
        for ii = 1:3
            if flip_vec(ii) == 1
                image_data = flip(image_data, ii);
            end
        end
    else
        image_data = permute(image_data, [2, 1, 3]);
        image_data = flip(flip(flip(image_data, 3), 2), 1);
    end
    
    nii_data = make_nii(image_data, resolution, offset, [], image_to_save.Title);
    save_nii(nii_data, full_filename);
    
    % cannot change affine matrix with matlab nifti tools
    % function below changes the orientation of the affine for given nifti
    % file.
    if exist('orientinfo','var')
        if strcmp(orientinfo.ref, 'LAS')
            % convert to RAS for nifti
            affine4x4 = orientinfo.affine4x4 * diag([-1,-1,1,1]);
            affine4x4(1,4) = affine4x4(1,4) * -1;
            affine4x4(2,4) = affine4x4(2,4) * -1;
        end
        affine4x4(1:3,1:3) = affine4x4(1:3,1:3)/abs(affine4x4(1:3,1:3));
        affine4x4(isnan(affine4x4)) = 0;
        writeniiaffonly(full_filename, affine4x4)
    end
end

