function path_name = MimSaveAs(image_data, patient_name, path_name, is_secondary_capture, dicom_metadata, reporting)
    % MimSaveAs. Prompts the user for a filename and file type, and saves the image
    %
    %     Syntax
    %     ------ 
    %
    %         MimSaveAs(image_data, patient_name, path_name, is_secondary_capture, dicom_metadata, reporting)
    %
    %             image_data      is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved
    %             patient_name    specifies the patient name to be stored in the image (only
    %                             used when there is no metadata available in the image)
    %             path_name       specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             is_secondary_capture   true if the image is derived, false if the pixel data 
    %                             directly corresponds to the original image pixel data
    %             dicom_metadata  a structure containing additional manufacturer tags
    %                             used to construct Dicom images
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
    
    if ~isa(image_data, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if nargin < 4 || isempty(is_secondary_capture)
        is_secondary_capture = false;
    end
    
    if nargin < 5 || isempty(dicom_metadata)
        dicom_metadata = MimDicomMetadata();
    end
    
    if nargin < 6
        reporting = CoreReportingDefault();
    end
    
    if islogical(image_data.RawImage)
        image_data = image_data.Copy;
        image_data.ChangeRawImage(uint8(image_data.RawImage));
    end

    [filename, path_name, filter_index] = SaveImageDialogBox(path_name);
    if filter_index ~= 0
        SaveImage(image_data, filename, path_name, filter_index, patient_name, is_secondary_capture, dicom_metadata, reporting);
    end
end

function [filename, path_name, filter_index] = SaveImageDialogBox(path_name)
    filespec = {'*.dcm', 'DICOM (*.dcm)';
                '*.mat', 'MATLAB matrix (*.mat)';
                '*.nii', 'NIFTI (*.nii)';
                '*.mhd', '8-bit metaheader and raw data (*.mhd)';
                '*.mhd', '16-bit metaheader and raw data (*.mhd)';
                };

    if path_name == 0
        [filename, path_name, filter_index] = uiputfile(filespec, 'Save image as');
    else
        [filename, path_name, filter_index] = uiputfile(filespec, 'Save image as', fullfile(path_name, ''));
    end
end
    
function SaveImage(image_data, filename, pathname, filter_index, patient_name, is_secondary_capture, dicom_metadata, reporting)
    reporting.Log(['Saving image ' filename]);

    if filter_index ~= 0 && ~isequal(filename,0) && ~isequal(pathname,0)
        reporting.Log(['Saving ' fullfile(pathname, filename)]);
        
        switch filter_index
            case 1
                MimSaveImageAsDicom(image_data, pathname, filename, patient_name, is_secondary_capture, dicom_metadata, reporting)
            case 2
                MimSaveAsMatlab(image_data, pathname, filename, reporting);
            case 3
                MimSaveAsNifti(image_data, pathname, filename, reporting);
            case 4
                MimSaveAsMetaheaderAndRaw(image_data, pathname, filename, 'char', reporting)
            case 5
                if MimImageUtilities.IsSigned(image_data)
                    MimSaveAsMetaheaderAndRaw(image_data, pathname, filename, 'short', reporting)
                else
                    MimSaveAsMetaheaderAndRaw(image_data, pathname, filename, 'ushort', reporting)
                end
        end
    end
end
