classdef TestContextHierarchy < PTKTest
    % TestContextHierarchy. Tests for the PTKContextHierarchy class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    methods
        function obj = TestContextHierarchy
            obj.TestFetchROIFromOrignalImage;
            obj.TestExtractROIFromOriginalImage;
            obj.TestExtractLeftAndRightLungs;
            obj.TestExtractLobes;
        end
        
        % Test 1 : check fetching image for same context
        function TestFetchROIFromOrignalImage(obj)    
            mock_reporting = MockReporting;
            mock_dependency_tracker = MockPluginDependencyTracker;
            mock_image_templates = MockImageTemplates;            
            context_hierarchy = PTKContextHierarchy(mock_dependency_tracker, mock_image_templates, mock_reporting);

            
            
            force_generate_image = true;
            mock_plugin_info = [];
            mock_plugin_info.GeneratePreview = true;
            mock_plugin_info.Context = PTKContextSet.LungROI;
            mock_plugin_info.PluginType = 'ReplaceOverlay';

            cache_info_1 = 'Cache Info 1';
            plugin_1 = 'Plugin1';
            dataset_uid_1 = '123';
            
            image_1 = PTKImage;
            image_1.Title = 'Image 1';
            
            results_1 = [];
            results_1.name = 'Result 1';
            results_1.ImageResult = image_1;
            
            mock_plugin = MockPlugin;
            
            mock_dependency_tracker.AddMockResult(plugin_1, PTKContext.LungROI, dataset_uid_1, results_1, cache_info_1, true);
            
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin_1, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid_1, [], force_generate_image, false, mock_reporting);
            
            obj.Assert(strcmp(result.name, results_1.name), 'Expected result');
            obj.Assert(strcmp(output_image.Title, image_1.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info_1), 'Expected run output');
        end
        
        % Test 2: test extracting an ROI region from the full lung
        function TestExtractROIFromOriginalImage(obj)
            mock_reporting = MockReporting;
            mock_dependency_tracker = MockPluginDependencyTracker;
            mock_image_templates = MockImageTemplates;            
            context_hierarchy = PTKContextHierarchy(mock_dependency_tracker, mock_image_templates, mock_reporting);

            
            
            
            cache_info_2 = 'Cache Info 2';
            plugin_2 = 'Plugin2';
            dataset_uid_2 = '456';
            
            force_generate_image = true;
            mock_plugin_info_2 = [];
            mock_plugin_info_2.GeneratePreview = true;
            mock_plugin_info_2.Context = PTKContextSet.OriginalImage;
            mock_plugin_info_2.PluginType = 'ReplaceOverlay';
            
            image_2 = PTKImage(zeros(10,10,10));
            image_2.Title = 'Image 2';
            
            results_2 = [];
            results_2.name = 'Result 2';
            results_2.ImageResult = image_2;
            mock_dependency_tracker.AddMockResult(plugin_2, PTKContext.OriginalImage, dataset_uid_2, results_2, cache_info_2, true);

            mock_plugin = MockPlugin;

            image_template_l = image_2.Copy;
            image_template_l.Crop([2,2,2], [7,7,7]);
            image_template_l = image_template_l.BlankCopy;
            image_template_l.Title = 'Template for ROI';
            
            mock_image_templates.AddMockImage(PTKContext.LungROI, image_template_l);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin_2, PTKContext.LungROI, [], mock_plugin_info_2, mock_plugin, dataset_uid_2, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.name, results_2.name), 'Expected result');
            obj.Assert(strcmp(output_image.Title, image_2.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info_2), 'Expected run output');
            obj.Assert(isequal(output_image.ImageSize, [6 6 6]), 'Image has been cropped');
        end
        
        % Test 3: test extracting left and right lung images, and concatenating
        % images to a higher context
        function TestExtractLeftAndRightLungs(obj)
            mock_reporting = MockReporting;
            mock_dependency_tracker = MockPluginDependencyTracker;
            mock_image_templates = MockImageTemplates;            
            context_hierarchy = PTKContextHierarchy(mock_dependency_tracker, mock_image_templates, mock_reporting);
            
            % Create images and image templates
            mock_original_image = PTKImage(ones(15,15,15));
            mock_original_image.Title = 'OriginalResultImage';
            mock_original_image.ChangeRawImage(uint8(rand(mock_original_image.ImageSize) > 0.5));
            template_original = mock_original_image.BlankCopy;
            template_original.Title = 'TemplateOriginal';
            
            mock_roi_image = mock_original_image.Copy;
            mock_roi_image.Crop([3, 4, 5], [12, 13, 14]);
            original_image_cropped = mock_roi_image.Copy;
            mock_roi_image.ChangeRawImage(uint8(rand(10,10,10) > 0.5));
            mock_roi_image.Title = 'ResultImage';
            template_roi = mock_roi_image.BlankCopy;
            template_roi.Title = 'TemplateROI';
            
            mock_lr_lung_image_raw = false(10,10,10);
            mock_lr_lung_image_raw_r = mock_lr_lung_image_raw;
            mock_lr_lung_image_raw_r(2:8, 1:3, 2:9) = true;
            mock_lr_lung_image_raw_l = mock_lr_lung_image_raw;
            mock_lr_lung_image_raw_l(3:9, 6:8, 3:9) = true;
            mock_lr_lung_image_raw = uint8(mock_lr_lung_image_raw_r) + 2*uint8(mock_lr_lung_image_raw_l);
            
            % Create templates for left and right lungs
            template_right = mock_roi_image.BlankCopy;
            template_right.ChangeRawImage(mock_lr_lung_image_raw_r);
            template_left = mock_roi_image.BlankCopy;
            template_left.ChangeRawImage(mock_lr_lung_image_raw_l);
            
            % Add templates to the template class
            mock_image_templates.AddMockImage(PTKContext.OriginalImage, template_original);
            mock_image_templates.AddMockImage(PTKContext.LungROI, template_roi);
            mock_image_templates.AddMockImage(PTKContext.LeftLung, template_left);
            mock_image_templates.AddMockImage(PTKContext.RightLung, template_right);
            
            % Create image defining left and right lungs
            mock_lr_lung_image = mock_roi_image.BlankCopy;
            mock_lr_lung_image.ChangeRawImage(mock_lr_lung_image_raw);
            mock_lr_lung_image.Title = 'LeftAndRight';
            
            
            cache_info_input = 'Cache Info';
            dataset_uid = '789';
            
            force_generate_image = true;
            plugin = 'Plugin';
            mock_plugin_info = [];
            mock_plugin_info.GeneratePreview = true;
            mock_plugin_info.Context = PTKContextSet.LungROI;
            mock_plugin_info.PluginType = 'ReplaceOverlay';
            
            plugin2 = 'Plugin2';
            mock_plugin_info2 = [];
            mock_plugin_info2.GeneratePreview = true;
            mock_plugin_info2.Context = PTKContextSet.OriginalImage;
            mock_plugin_info2.PluginType = 'ReplaceOverlay';

            plugin3 = 'Plugin3';
            mock_plugin_info3 = [];
            mock_plugin_info3.GeneratePreview = true;
            mock_plugin_info3.Context = PTKContextSet.SingleLung;
            mock_plugin_info3.PluginType = 'ReplaceOverlay';
            
            results = mock_roi_image.Copy;
            results_original = mock_original_image.Copy;
            
            left_image = template_left.Copy;
            left_image.ChangeRawImage(uint8(left_image.RawImage).*uint8(rand(left_image.ImageSize) > 0.5));
            left_image.Title = 'LeftResultImage';
            right_image = template_right.Copy;
            right_image.ChangeRawImage(uint8(right_image.RawImage).*uint8(rand(right_image.ImageSize) > 0.5));
            right_image.Title = 'RightResultImage';
            
            mock_dependency_tracker.AddMockResult(plugin, PTKContext.LungROI, dataset_uid, results, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin2, PTKContext.OriginalImage, dataset_uid, results_original, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin3, PTKContext.LeftLung, dataset_uid, left_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin3, PTKContext.RightLung, dataset_uid, right_image, cache_info_input, true);

            mock_plugin = MockPlugin;
            mock_plugin2 = MockPlugin;
            mock_plugin3 = MockPlugin;
            

            % Fetch a result for the LungROI from a plugin that has a
            % LungROI context set            
            result = context_hierarchy.GetResult(plugin, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_roi_image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_roi_image.RawImage)), 'Image is correct ROI');
            
            % Fetch a result for the left lung from a plugin that has a
            % LungROI context set            
            result = context_hierarchy.GetResult(plugin, PTKContext.LeftLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LeftLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_l & mock_roi_image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_l & mock_roi_image.RawImage)), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has a
            % LungROI context set            
            result = context_hierarchy.GetResult(plugin, PTKContext.RightLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.RightLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_r & mock_roi_image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_r & mock_roi_image.RawImage)), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin2, PTKContext.RightLung, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.RightLung, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_r & original_image_cropped.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_r & original_image_cropped.RawImage)), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin3, PTKContext.OriginalImage, [], mock_plugin_info3, mock_plugin3, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin3, PTKContext.OriginalImage, [], mock_plugin_info3, mock_plugin3, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.LungROI.LeftLung.Title, left_image.Title), 'Expected result');
            obj.Assert(strcmp(result.LungROI.RightLung.Title, right_image.Title), 'Expected result');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.LeftLung, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.RightLung, cache_info_input), 'Expected run output');
            obj.Assert(isequal(result.LungROI.LeftLung.RawImage, left_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.RightLung.RawImage, right_image.RawImage), 'Image is correct ROI');
            
            
            expected_output_image = mock_original_image.Copy;
            expected_output_image.Clear;
            expected_output_image.ChangeSubImageWithMask(left_image, template_left);
            expected_output_image.ChangeSubImageWithMask(right_image, template_right);
            obj.Assert(isequal(output_image.RawImage, expected_output_image.RawImage), 'Image is correct ROI');
            
        end
        
        % Test 4: test extracting lobes, and concatenating
        % images to a higher context
        function TestExtractLobes(obj)
            mock_reporting = MockReporting;
            mock_dependency_tracker = MockPluginDependencyTracker;
            mock_image_templates = MockImageTemplates;
            context_hierarchy = PTKContextHierarchy(mock_dependency_tracker, mock_image_templates, mock_reporting);
            
            % Create images and image templates
            mock_original_image = PTKImage(ones(15,15,15));
            mock_original_image.Title = 'OriginalResultImage';
            mock_original_image.ChangeRawImage(uint8(rand(mock_original_image.ImageSize) > 0.5));
            template_original = mock_original_image.BlankCopy;
            template_original.Title = 'TemplateOriginal';
            
            mock_roi_image = mock_original_image.Copy;
            mock_roi_image.Crop([3, 4, 5], [12, 13, 14]);
            original_image_cropped = mock_roi_image.Copy;
            mock_roi_image.ChangeRawImage(uint8(rand(10,10,10) > 0.5));
            mock_roi_image.Title = 'ResultImage';
            template_roi = mock_roi_image.BlankCopy;
            template_roi.Title = 'TemplateROI';
            
            mock_lr_lung_image_raw = false(10,10,10);
            mock_lr_lung_image_raw_r = mock_lr_lung_image_raw;
            mock_lr_lung_image_raw_r(2:8, 1:3, 2:9) = true;
            mock_lr_lung_image_raw_l = mock_lr_lung_image_raw;
            mock_lr_lung_image_raw_l(3:9, 6:8, 3:9) = true;
            mock_lr_lung_image_raw = uint8(mock_lr_lung_image_raw_r) + 2*uint8(mock_lr_lung_image_raw_l);

            mock_lobe_image_raw = false(10,10,10);
            mock_lobe_image_raw_ru = mock_lobe_image_raw;
            mock_lobe_image_raw_rm = mock_lobe_image_raw;
            mock_lobe_image_raw_rl = mock_lobe_image_raw;
            mock_lobe_image_raw_lu = mock_lobe_image_raw;
            mock_lobe_image_raw_ll = mock_lobe_image_raw;
            mock_lobe_image_raw_ru(2:8, 1:3, 2:4) = true;
            mock_lobe_image_raw_rm(2:8, 1:3, 5:6) = true;
            mock_lobe_image_raw_rl(2:8, 1:3, 7:9) = true;
            mock_lobe_image_raw_lu(3:9, 6:8, 3:5) = true;
            mock_lobe_image_raw_ll(3:9, 6:8, 7:9) = true;
            mock_lobe_image_raw = uint8(mock_lobe_image_raw_ru) + 2*uint8(mock_lobe_image_raw_rm) + ...
                + 4*uint8(mock_lobe_image_raw_rl) + 5*uint8(mock_lobe_image_raw_lu) + 6*uint8(mock_lobe_image_raw_ll);
            
            % Create templates for left and right lungs
            template_right = mock_roi_image.BlankCopy;
            template_right.ChangeRawImage(mock_lr_lung_image_raw_r);
            template_left = mock_roi_image.BlankCopy;
            template_left.ChangeRawImage(mock_lr_lung_image_raw_l);

            % Create templates for lobes
            template_ru = mock_roi_image.BlankCopy;
            template_ru.ChangeRawImage(mock_lobe_image_raw_ru);
            template_rm = mock_roi_image.BlankCopy;
            template_rm.ChangeRawImage(mock_lobe_image_raw_rm);
            template_rl = mock_roi_image.BlankCopy;
            template_rl.ChangeRawImage(mock_lobe_image_raw_rl);
            template_lu = mock_roi_image.BlankCopy;
            template_lu.ChangeRawImage(mock_lobe_image_raw_lu);
            template_ll = mock_roi_image.BlankCopy;
            template_ll.ChangeRawImage(mock_lobe_image_raw_ll);
            
%             template_roi.CropToFit;
            template_left.CropToFit;
            template_right.CropToFit;
            template_ru.CropToFit;
            template_rm.CropToFit;
            template_rl.CropToFit;
            template_lu.CropToFit;
            template_ll.CropToFit;
            
            % Add templates to the template class
            mock_image_templates.AddMockImage(PTKContext.OriginalImage, template_original);
            mock_image_templates.AddMockImage(PTKContext.LungROI, template_roi);
            mock_image_templates.AddMockImage(PTKContext.LeftLung, template_left);
            mock_image_templates.AddMockImage(PTKContext.RightLung, template_right);
            mock_image_templates.AddMockImage(PTKContext.RightUpperLobe, template_ru);
            mock_image_templates.AddMockImage(PTKContext.RightMiddleLobe, template_rm);
            mock_image_templates.AddMockImage(PTKContext.RightLowerLobe, template_rl);
            mock_image_templates.AddMockImage(PTKContext.LeftUpperLobe, template_lu);
            mock_image_templates.AddMockImage(PTKContext.LeftLowerLobe, template_ll);
            
            % Create image defining left and right lungs
            mock_lr_lung_image = mock_roi_image.BlankCopy;
            mock_lr_lung_image.ChangeRawImage(mock_lr_lung_image_raw);
            mock_lr_lung_image.Title = 'LeftAndRight';
            
            % Create image defining lobes
            mock_lobe_lung_image = mock_roi_image.BlankCopy;
            mock_lobe_lung_image.ChangeRawImage(mock_lobe_image_raw);
            mock_lobe_lung_image.Title = 'Lobes';
            
            cache_info_input = 'Cache Info';
            dataset_uid = '789';
            
            force_generate_image = true;
            plugin = 'Plugin';
            mock_plugin_info = [];
            mock_plugin_info.GeneratePreview = true;
            mock_plugin_info.Context = PTKContextSet.LungROI;
            mock_plugin_info.PluginType = 'ReplaceOverlay';
            
            plugin2 = 'Plugin2';
            mock_plugin_info2 = [];
            mock_plugin_info2.GeneratePreview = true;
            mock_plugin_info2.Context = PTKContextSet.OriginalImage;
            mock_plugin_info2.PluginType = 'ReplaceOverlay';

            plugin3 = 'Plugin3';
            mock_plugin_info3 = [];
            mock_plugin_info3.GeneratePreview = true;
            mock_plugin_info3.Context = PTKContextSet.SingleLung;
            mock_plugin_info3.PluginType = 'ReplaceOverlay';
            
            plugin4 = 'Plugin4';
            mock_plugin_info4 = [];
            mock_plugin_info4.GeneratePreview = true;
            mock_plugin_info4.Context = PTKContextSet.Lobe;
            mock_plugin_info4.PluginType = 'ReplaceOverlay';
            
            results = mock_roi_image.Copy;
            results_original = mock_original_image.Copy;
            
            left_image = template_left.Copy;
            left_image.ChangeRawImage(uint8(left_image.RawImage).*uint8(rand(left_image.ImageSize) > 0.5));
            left_image.Title = 'LeftResultImage';
            right_image = template_right.Copy;
            right_image.ChangeRawImage(uint8(right_image.RawImage).*uint8(rand(right_image.ImageSize) > 0.5));
            right_image.Title = 'RightResultImage';
            ru_image = template_ru.Copy;
            ru_image.ChangeRawImage(uint8(ru_image.RawImage).*uint8(rand(ru_image.ImageSize) > 0.5));
            ru_image.Title = 'RUResultImage';
            rm_image = template_rm.Copy;
            rm_image.ChangeRawImage(uint8(rm_image.RawImage).*uint8(rand(rm_image.ImageSize) > 0.5));
            rm_image.Title = 'RMResultImage';
            rl_image = template_rl.Copy;
            rl_image.ChangeRawImage(uint8(rl_image.RawImage).*uint8(rand(rl_image.ImageSize) > 0.5));
            rl_image.Title = 'RLResultImage';
            lu_image = template_lu.Copy;
            lu_image.ChangeRawImage(uint8(lu_image.RawImage).*uint8(rand(lu_image.ImageSize) > 0.5));
            lu_image.Title = 'LUResultImage';
            ll_image = template_ll.Copy;
            ll_image.ChangeRawImage(uint8(ll_image.RawImage).*uint8(rand(ll_image.ImageSize) > 0.5));
            ll_image.Title = 'LLResultImage';
            
            mock_dependency_tracker.AddMockResult(plugin, PTKContext.LungROI, dataset_uid, results, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin2, PTKContext.OriginalImage, dataset_uid, results_original, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin3, PTKContext.LeftLung, dataset_uid, left_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin3, PTKContext.RightLung, dataset_uid, right_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.RightUpperLobe, dataset_uid, ru_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.RightMiddleLobe, dataset_uid, rm_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.RightLowerLobe, dataset_uid, rl_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.LeftUpperLobe, dataset_uid, lu_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.LeftLowerLobe, dataset_uid, ll_image, cache_info_input, true);

            mock_plugin = MockPlugin;
            mock_plugin2 = MockPlugin;
            mock_plugin3 = MockPlugin;
            mock_plugin4 = MockPlugin;
            

            result = context_hierarchy.GetResult(plugin, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            
            % Fetch a result for the left lung from a plugin that has a
            % LungROI context set
            result = context_hierarchy.GetResult(plugin, PTKContext.LeftLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LeftLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_left, mock_roi_image))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_left, mock_roi_image))), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has a
            % LungROI context set
            result = context_hierarchy.GetResult(plugin, PTKContext.RightLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.RightLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_right, mock_roi_image))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_right, mock_roi_image))), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin2, PTKContext.RightLung, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.RightLung, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_right, original_image_cropped))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_right, original_image_cropped))), 'Image is correct ROI');
            
            % Fetch a result for the whole lung from a plugin with a lung
            % context set
            result = context_hierarchy.GetResult(plugin3, PTKContext.OriginalImage, [], mock_plugin_info3, mock_plugin3, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin3, PTKContext.OriginalImage, [], mock_plugin_info3, mock_plugin3, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.LungROI.LeftLung.Title, left_image.Title), 'Expected result');
            obj.Assert(strcmp(result.LungROI.RightLung.Title, right_image.Title), 'Expected result');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.LeftLung, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.RightLung, cache_info_input), 'Expected run output');
            obj.Assert(isequal(result.LungROI.LeftLung.RawImage, left_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.RightLung.RawImage, right_image.RawImage), 'Image is correct ROI');
            
            
            
            % Lobar checks
            
            % Fetch a result for the upper right lobe from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin2, PTKContext.RightUpperLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.RightUpperLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_ru, original_image_cropped))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_ru, original_image_cropped))), 'Image is correct ROI');
            
            % Fetch a result for the middle right lobe from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin2, PTKContext.RightMiddleLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.RightMiddleLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_rm, original_image_cropped))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_rm, original_image_cropped))), 'Image is correct ROI');
            
            % Fetch a result for the lower right lobe from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin2, PTKContext.RightLowerLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.RightLowerLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_rl, original_image_cropped))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_rl, original_image_cropped))), 'Image is correct ROI');
            
            % Fetch a result for the upper left lobe from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin2, PTKContext.LeftUpperLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.LeftUpperLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_lu, original_image_cropped))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_lu, original_image_cropped))), 'Image is correct ROI');
                        
            % Fetch a result for the lower left lobe from a plugin that has an
            % OriginalImage context set
            result = context_hierarchy.GetResult(plugin2, PTKContext.LeftLowerLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.LeftLowerLobe, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_ll, original_image_cropped))), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(TestContextHierarchy.CombineAndCrop(template_ll, original_image_cropped))), 'Image is correct ROI');

            
            
            % Fetch a result for the whole lung from a plugin with a lobe
            % context set
            result = context_hierarchy.GetResult(plugin4, PTKContext.OriginalImage, [], mock_plugin_info4, mock_plugin4, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin4, PTKContext.OriginalImage, [], mock_plugin_info4, mock_plugin4, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.LungROI.LeftLung.LeftUpperLobe.Title, lu_image.Title), 'Expected result');
            obj.Assert(strcmp(result.LungROI.RightLung.RightUpperLobe.Title, ru_image.Title), 'Expected result');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.LeftLung.LeftUpperLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.LeftLung.LeftLowerLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.RightLung.RightUpperLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.RightLung.RightMiddleLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.RightLung.RightLowerLobe, cache_info_input), 'Expected run output');
            obj.Assert(isequal(result.LungROI.LeftLung.LeftUpperLobe.RawImage, lu_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.LeftLung.LeftLowerLobe.RawImage, ll_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.RightLung.RightUpperLobe.RawImage, ru_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.RightLung.RightMiddleLobe.RawImage, rm_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.RightLung.RightLowerLobe.RawImage, rl_image.RawImage), 'Image is correct ROI');

            expected_output_image = mock_original_image.Copy;
            expected_output_image.Clear;
            expected_output_image.ChangeSubImageWithMask(lu_image, template_lu);
            expected_output_image.ChangeSubImageWithMask(ll_image, template_ll);
            expected_output_image.ChangeSubImageWithMask(ru_image, template_ru);
            expected_output_image.ChangeSubImageWithMask(rm_image, template_rm);
            expected_output_image.ChangeSubImageWithMask(rl_image, template_rl);
            obj.Assert(isequal(output_image.RawImage, expected_output_image.RawImage), 'Image is correct ROI');
            
        end
    end
    
    methods (Static)
        function combined_raw = CombineAndCrop(template, roi)
            roi = roi.Copy;
            roi.ResizeToMatch(template)
            combined_raw = template.RawImage & roi.RawImage;
        end
        
        
    end    
end

