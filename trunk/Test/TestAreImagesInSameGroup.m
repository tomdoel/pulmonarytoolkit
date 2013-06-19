classdef TestAreImagesInSameGroup < PTKTest
    % TestAreImagesInSameGroup. Tests for the PTKAreImagesInSameGroup function.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestAreImagesInSameGroup
            this_metadata = [];
            other_metadata = [];
            
            % For images to be in the same group, the following tags must either
            % be present in both metadata, or not present in both metadata. If
            % present, they must be equal. We check that the test passes in
            % these cases and fails otherwise
            
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'PatientName', 'Name1', 'Name2');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'PatientID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'PatientBirthDate');
            
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'StudyInstanceUID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'SeriesInstanceUID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'StudyID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'StudyDescription');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'SeriesNumber');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'SeriesDescription', 'Series Description 1', 'Series Description 2');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'StudyDate');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'SeriesDate');
            
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'Rows', 256, 512);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'Columns', 256, 512);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'Width', 256, 512);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'Height', 256, 512);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'PixelSpacing', [1 2], [3 4]);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'PatientPosition');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'ImageOrientationPatient', [1;0;0;0;1;0], [0;1;0;0;0;1]);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'FrameOfReferenceUID');
            
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'Modality', 'CT', 'MR');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'BitDepth', 1, 2);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'ColorType');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'MediaStorageSOPClassUID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'TransferSyntaxUID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'ImageType', 'ORIGINAL\PRIMARY\AXIAL', 'ORIGINAL\PRIMARY');            
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'SOPClassUID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'ImplementationClassUID');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'ImagesInAcquisition', 100, 102);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'SamplesPerPixel', 1, 2);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'PhotometricInterpretation');
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'BitsAllocated', 1, 2);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'BitsStored', 1, 2);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'HighBit', 1, 2);
            [this_metadata, other_metadata] = obj.CheckMatchingOfTags(this_metadata, other_metadata, 'PixelRepresentation');

            % Slice location tags: existence must match but values do not have
            % to match
            this_metadata.SliceLocation = 1;
            obj.Assert(~PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should fail');
            other_metadata.SliceLocation = 2;
            obj.Assert(PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should pass');
            
            % ImagePositionPatient tag: existence must match and 2 of the 3 values must match
            this_metadata.ImagePositionPatient = [1;2;3];
            obj.Assert(~PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should fail');
            other_metadata.ImagePositionPatient = [4;5;6];
            obj.Assert(~PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should fail');
            other_metadata.ImagePositionPatient = [1;5;6];
            obj.Assert(~PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should fail');
            other_metadata.ImagePositionPatient = [1;2;6];
            obj.Assert(PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should pass');
            other_metadata.ImagePositionPatient = [7;2;3];
            obj.Assert(PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should pass');
            other_metadata.ImagePositionPatient = [1;8;3];
            obj.Assert(PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should pass');
            
        end
    end
    
    methods (Access = private)
        function [this_metadata, other_metadata] = CheckMatchingOfTags(obj, this_metadata, other_metadata, tag_name, value_1, value_2)
            if nargin < 6
                value_2 = PTKSystemUtilities.GenerateUid;
            end
            if nargin < 5
                value_1 = PTKSystemUtilities.GenerateUid;
            end
            
            % Images should match if the tag is not present in either
            obj.Assert(PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should pass');
            
            % Images should not match if one contains a tag
            this_metadata.(tag_name) = value_1;
            obj.Assert(~PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should fail');
            
            % Images should not match if the tags don't match
            other_metadata.(tag_name) = value_2;
            obj.Assert(~PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should fail');
            
            % Images should match if the tags match
            other_metadata.(tag_name) = value_1;
            obj.Assert(PTKAreImagesInSameGroup(this_metadata, other_metadata), 'Should pass');
        end
    end
end
            
