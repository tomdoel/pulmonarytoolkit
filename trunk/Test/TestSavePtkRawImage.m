classdef TestSavePtkRawImage < PTKTest
    % TestSavePtkRawImage. Tests for the TestSavePtkRawImage and TestLoadPtkRawImage class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestSavePtkRawImage
            reporting = PTKReportingDefault;
            obj.TestSaveLoad('uint8', reporting);
            obj.TestSaveLoad('int8', reporting);
            obj.TestSaveLoad('uint16', reporting);
            obj.TestSaveLoad('int16', reporting);
            obj.TestSaveLoad('uint32', reporting);
            obj.TestSaveLoad('int32', reporting);
            obj.TestSaveLoad('uint64', reporting);
            obj.TestSaveLoad('int64', reporting);
            obj.TestSaveLoad('single', reporting);
            obj.TestSaveLoad('double', reporting);
            obj.TestSaveLoad('logical', reporting);
        end
        
        function TestSaveLoad(obj, data_type, reporting)
            for index = 1 : 20
                image_size = round(2 + 100*rand([1, 3]));
                ptk_temp_dir = fullfile(tempdir, 'ptk_test');
                PTKDiskUtilities.CreateDirectoryIfNecessary(ptk_temp_dir);
                raw_image = rand(image_size);
                
                switch data_type
                    case 'single'
                        raw_image = single(raw_image);
                    case 'double'
                        raw_image = double(raw_image);
                    case 'logical'
                        raw_image = logical(raw_image > 0.5);
                    case 'uint8'
                        raw_image = round(255*raw_image);
                    case 'uint16'
                        raw_image = round(65535*raw_image);
                    case 'uint32'
                        raw_image = round(4294967295*raw_image);
                    case 'uint64'
                        raw_image = round(18446744073709551615*raw_image);
                    case 'int8'
                        raw_image = round(255*raw_image) - 128;
                    case 'int16'
                        raw_image = round(65535*raw_image) - 32768;
                    case 'int32'
                        raw_image = round(4294967295*raw_image) - 2147483648;
                    case 'int64'
                        raw_image = round(18446744073709551615*raw_image) - 9223372036854775808;
                end           
                
                raw_image = cast(raw_image, data_type);

                obj.TestSaveLoadForCompression(raw_image, ptk_temp_dir, 'test_deflate.raw', 'deflate', reporting);
                obj.TestSaveLoadForCompression(raw_image, ptk_temp_dir, 'test_uncompressed.raw', [], reporting);
            end
        end
        
        function TestSaveLoadForCompression(obj, raw_image, ptk_temp_dir, raw_file_name, compression, reporting)
            PTKSavePtkRawImage(raw_image, ptk_temp_dir, raw_file_name, compression, reporting);
            raw_image_loaded = PTKLoadPtkRawImage(ptk_temp_dir, raw_file_name, class(raw_image), size(raw_image), compression, reporting);
            obj.Assert(isequal(raw_image, raw_image_loaded), 'Images are identical');
        end
    end    
end

