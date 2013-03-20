classdef PTKDicomImage < PTKImage
    % PTKDicomImage. A class for holding a 3D medical image volume.
    %
    %     PTKDicomImage is inherited from the fundamental PTKImage image class 
    %     used by the Pulmonary Toolkit. It provides additional routines and
    %     metadata associated with medical imaging data, most commonly imported
    %     from the DICOM standard.
    %
    %     In general, you do not need to create PTKDicomImages using the
    %     constructor. You should import data using function such as
    %     PTKLoadImageFromDicomFiles() which correctly set the metadata.
    %     Thereafter, use .Copy() to make copies of the image, and .BlankCopy()
    %     followed by .ChangeRawImage() to create derived images. See PTKImage.m
    %     for an example of creating functions which modify images contained in
    %     PTKImage classes.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        Modality
        RescaleSlope
        RescaleIntercept
        RescaleUnits = ''
        IsCT = false
        IsMR = false
        MetaHeader
        StudyUid
    end
    
    methods (Static)
        function new_dicom_image = CreateDicomImageFromMetadata(original_image, metadata, slice_thickness, global_origin_mm, reporting)

            % Our voxel size should be equal to SpacingBetweenSlices. However, 
            % some scanners incorrectly set SpacingBetweenSlices as the
            % gap between slices, instead of the centre-to-centre distance.
            % To ensure correct reconstruction interval, should really use
            % patient image Position tag (0020,0032)
            % http://www.itk.org/pipermail/insight-users/2005-September/014
            % 711.html
            voxelsize_z = slice_thickness;
             
            voxel_size = [metadata.PixelSpacing' voxelsize_z];
            
            new_dimension_order = PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation(metadata.ImageOrientationPatient, reporting);
            original_image = permute(original_image, new_dimension_order);
            voxel_size = voxel_size(new_dimension_order);
            global_origin_mm = global_origin_mm([2 1 3]);
            
            if isfield(metadata, 'RescaleSlope')
                rescale_slope = metadata.RescaleSlope;
            else
                rescale_slope = [];
            end
            
            if isfield(metadata, 'RescaleIntercept')
                rescale_intercept = metadata.RescaleIntercept;
            else
                rescale_intercept = [];
            end

            new_dicom_image = PTKDicomImage( ...
                original_image, rescale_slope, rescale_intercept, voxel_size, metadata.Modality, metadata.StudyInstanceUID, metadata ...
            );
            patient_name = '';
            study_description = '';
            series_description = '';
            if isfield(metadata, 'PatientName')
                if isfield(metadata.PatientName, 'FamilyName')
                    patient_name = ['', metadata.PatientName.FamilyName, ' '];
                end
            end
            if isfield(metadata, 'StudyDescription')
                study_description = ['/ ', metadata.StudyDescription, ' '];
            end
            if isfield(metadata, 'SeriesDescription')
                study_description = ['/ ', metadata.SeriesDescription, ' '];
            end
            
            new_dicom_image.Title = [patient_name, study_description, series_description];
            new_dicom_image.GlobalOrigin = global_origin_mm;
            
        end
    end
    
    methods
        % The meta_data argument is optional, and is only used for saving DICOM
        % files. Other arguments are compulsory
        function obj = PTKDicomImage(original_image, rescale_slope, rescale_intercept, voxel_size, modality, study_uid, meta_data)
            
            obj = obj@PTKImage(original_image, PTKImageType.Grayscale, voxel_size);
            
            obj.StudyUid = study_uid;
            
            if exist('meta_data', 'var')
                obj.MetaHeader = meta_data;
            end

            if strcmp(modality, 'CT')
                obj.IsCT = true;
                obj.RescaleSlope = rescale_slope;
                obj.RescaleIntercept = rescale_intercept;
                obj.RescaleUnits = 'HU';
            elseif strcmp(modality, 'MR')                
                obj.IsMR = true;
                obj.RescaleSlope = [];
                obj.RescaleIntercept = [];
            end
        end
        
        function [value, units] = GetRescaledValue(obj, global_coords)
            if obj.IsCT
                value = obj.GreyscaleToHounsfield(obj.GetVoxel(global_coords));
                units = obj.RescaleUnits;
            else
                [value, units] = GetRescaledValue@PTKImage(obj, global_coords);
            end
        end
        
        function units_rescaled = GrayscaleToRescaled(obj, units_greyscale)
            if obj.IsCT
                units_rescaled = obj.GreyscaleToHounsfield(units_greyscale);
            else
                units_rescaled = units_greyscale;
            end
        end

        function units_greyscale = RescaledToGrayscale(obj, units_rescaled)
            if obj.IsCT
                units_greyscale = obj.HounsfieldToGreyscale(units_rescaled);
            else
                units_greyscale = units_rescaled;
            end
        end

        function units_greyscale = HounsfieldToGreyscale(obj, units_hu)
            % Conversion from Hounsfield units to image raw intensity values:
            if obj.IsCT
                units_greyscale = (units_hu - obj.RescaleIntercept)/obj.RescaleSlope;
            else
               error('The HounsfieldToGreyscale() method was called, but this is not a CT image'); 
            end
        end
        
        function units_hu = GreyscaleToHounsfield(obj, units_greyscale)
            % Conversion from image raw intensity values to Hounsfield units:
            if obj.IsCT
                units_hu = int16(units_greyscale)*obj.RescaleSlope + obj.RescaleIntercept;
            else
               error('The HounsfieldToGreyscale() method was called, but this is not a CT image'); 
            end
        end
        
        function units_rescaled = RescaledToGreyscale(obj, units_rescaled)
            if obj.IsCT || obj.IsMR
                units_rescaled = obj.HounsfieldToGreyscale(units_rescaled);
            else
                error('The RescaledToGreyscale() method was called, but this is not a CT or MR image');    
            end
            
        end

        function copy = Copy(obj)
            copy = PTKDicomImage(obj.RawImage, obj.RescaleSlope, obj.RescaleIntercept, obj.VoxelSize, obj.Modality, obj.StudyUid, obj.MetaHeader);
            metaclass = ?PTKDicomImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~property.Constant)
                    copy.(property.Name) = obj.(property.Name);
                end
            end
        end
        
        function copy = BlankCopy(obj)
            copy = PTKDicomImage([], obj.RescaleSlope, obj.RescaleIntercept, obj.VoxelSize, obj.Modality, obj.StudyUid, obj.MetaHeader);
            metaclass = ?PTKDicomImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~property.Constant) && (~strcmp(property.Name, 'RawImage'))
                    copy.(property.Name) = obj.(property.Name);
                end
            end
        end
        
        function is_equal = eq(obj, other)
            metaclass = ?PTKImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~ismember(property.Name, obj.PropertiesToIgnoreOnComparison))
                    if ~isequal(other.(property.Name), obj.(property.Name))
                        is_equal = false;
                        return;
                    end
                end
            end
            is_equal = true;
        end        
    end
end

