classdef TestLoadSaveXML < CoreTest
    % TestLoadSaveXML. Tests for loading and saving XML files
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestLoadSaveXML
            reporting = CoreReportingDefault;
            test_class = obj.getTestClass('MimStruct');
            obj.TestLoadAndSave(test_class, reporting);
            test_class_2 = obj.getTestClass('TestClass');
            obj.TestLoadAndSaveWithClassConversion(test_class_2, reporting, 'MimStruct');
        end

        function test_class = getTestClass(obj, class_name)
            test_class = feval(class_name);
            test_class.AddField('Avalue', 'ValueA');
            test_class.AddField('Bvalue', [42, 1, -53, 9]);
            test_class.AddField('Cvalue', uint8(43));
            test_class.AddField('Dvalue', magic(5));
            test_class.AddField('Evalue', {magic(6), magic(5)});
            test_class.AddField('Fvalue', -42);
            test_class.AddField('Gvalue', [true, false; false, true]);
            test_class.AddField('Hvalue', [42; -1; -53; 99]);
            test_class.AddField('Ivalue', {magic(2), magic(3); [1,2,3], 'Magic'; [], false});
            
            im_info = obj.GetTestImageInfo;
            test_class.AddField('Jvalue', im_info);
            
            test_struct = obj.GetTestStruct;
            test_class.AddField('KValue', test_struct);
            
            map = obj.GetTestMap;
            test_class.AddField('LValue', map);
        end

        function map = GetTestMap(obj)
            map = containers.Map;
            map('A') = 'String1';
            map('1') = 'String1';
            map('J') = 'String3';
            map('AZZZ') = 'String4';
        end
        
        function im_info = GetTestImageInfo(obj)
            im_info = MimImageInfo;
            im_info.ImagePath = 'ABCDE/GHIJK';
            im_info.ImageFilenames = {'0.dcm', '1.dcm', '2.dcm'};
            im_info.ImageFileFormat = MimImageFileFormat.Matlab;
            im_info.Modality = 'CT';
        end
        
        function test_struct = GetTestStruct(obj)
            test_struct = struct;
            test_struct.StructA = [42, 1, -53, 9];
            test_struct.Avalue = 'ValueA';
            test_struct.Bvalue = [42, 1, -53, 9];
            test_struct.Fvalue = -42;
            test_struct.Cvalue = uint8(43);
            test_struct.Dvalue = magic(5);
            test_struct.Evalue = {magic(6), magic(5)};
            test_struct.Gvalue = [true, false; false, true];
            test_struct.Hvalue = [42; -1; -53; 99];
            test_struct.Ivalue = {magic(2), magic(3); [1,2,3], 'Blah'; [], false};
        end
        
        
        function TestLoadAndSave(obj, base_class, reporting)
            temp_folder = tempdir;
            file_name = 'TestXML.xml';
            CoreSaveXml(base_class, 'Test', CoreFilename(temp_folder, file_name), reporting);
            loaded_base_class = CoreLoadXml(CoreFilename(temp_folder, file_name), reporting);
            loaded_base_class = loaded_base_class.Test;
            
            obj.TestEquality(base_class, loaded_base_class);
            obj.Assert(isequal(class(base_class), class(loaded_base_class)), 'Same class');
        end

        function TestLoadAndSaveWithClassConversion(obj, base_class, reporting, new_class_name)
            temp_folder = tempdir;
            file_name = 'TestXML.xml';
            CoreSaveXml(base_class, 'Test', CoreFilename(temp_folder, file_name), reporting);
            
            conversion_map = containers.Map;
            conversion_map(class(base_class)) = new_class_name;
            loaded_base_class = CoreLoadXml(CoreFilename(temp_folder, file_name), reporting, conversion_map);
            loaded_base_class = loaded_base_class.Test;
            
            obj.TestEquality(base_class, loaded_base_class);
            obj.Assert(~isequal(class(base_class), class(loaded_base_class)), 'Not same class');
            obj.Assert(isequal(new_class_name, class(loaded_base_class)), 'Not same class');
        end
        
        function TestEquality(obj, class_1, class_2)
            % Custom compare method because isequal does not work with dynamicprops
            p1 = properties(class_1);
            p2 = properties(class_2);
            obj.Assert(isequal(sort(p1), sort(p2)), 'Property lists are identical');
            for p = p1'
                obj.Assert(isequal(class_1.(p{1}), class_2.(p{1})), 'Property values are identical');
            end
        end
        

    end
end