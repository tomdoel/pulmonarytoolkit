function MimSaveNiftiAsNifti(image_to_save, path, filename, reporting)
    % MimSaveAsNifti. Writes out a PTKImage in NIFTI format if originally
    % loaded from NIFTI format using PTK.
    %
    %     Syntax
    %     ------
    %
    %         MimSaveNiftiAsNifti(image_data, path, filename, data_type, orientation, reporting)
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
    %     Author: Ashkan Pakzad, ashkanpakzad.github.io
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

    % x y switch
    resolution = image_to_save.VoxelSize([2, 1, 3]);
    image_data = permute(image_data, [2, 1, 3]);
    image_data = flip(image_data, 3); % switch data LPI to LPS
    
    
    % populate header class to with required accurate fields
    metadata = image_to_save.MetaHeader;
    metadata.Filename = full_filename;
    metadata.ImageSize = size(image_data);
    metadata.PixelDimensions = resolution;
    metadata.Datatype = class(image_data);
    
    niftiwrite(image_data, full_filename, metadata);
    
    % cannot change affine matrix with matlab nifti tools
    % function below changes the orientation of the affine for given nifti
    % file.
    affine4x4 = metadata.Transform.T;
    affine3x3 = affine4x4(1:3,1:3);
    affine3x3 = affine3x3/abs(affine3x3);
    affine3x3(isnan(affine3x3)) = 0;
    writeniiaffine(full_filename, affine3x3)
end

