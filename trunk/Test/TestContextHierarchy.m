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
            obj.TestFetchResultForSameContext;
            obj.TestExtractROIFromOriginalImage;
            obj.TestExtractLeftAndRightLungs;
            obj.TestExtractLobes;
        end
        
        function TestFetchResultForSameContext(obj)
            % Test 1 : check fetching image for same context
            
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
            
            % Test saving an edited version of this result
            edited_image_1 = PTKImage;
            edited_image_1.Title = 'Edited Image 1';
            context_hierarchy.SaveEditedResult(plugin_1, PTKContext.LungROI, edited_image_1, mock_plugin_info, [], dataset_uid_1, mock_reporting);
            saved_edited_result = mock_dependency_tracker.SavedMockResults([plugin_1 '.' char(PTKContext.LungROI) '.' dataset_uid_1]);
            obj.Assert(strcmp(saved_edited_result.Title, edited_image_1.Title), 'Expected image');
            

            % Test fetching an original image context from original image plugin
            mock_plugin_2 = MockPlugin;
            plugin_2 = 'Plugin2';
            results_2 = [];
            results_2.name = 'Result 2';
            image_2 = PTKImage;
            image_2.Title = 'Image 2';
            results_2.ImageResult = image_2;
            cache_info_2 = 'Cache Info 2';
            mock_plugin_info_2 = [];
            mock_plugin_info_2.GeneratePreview = true;
            mock_plugin_info_2.Context = PTKContextSet.OriginalImage;
            mock_plugin_info_2.PluginType = 'ReplaceOverlay';
            

            mock_dependency_tracker.AddMockResult(plugin_2, PTKContext.OriginalImage, dataset_uid_1, results_2, cache_info_2, true);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin_2, PTKContext.OriginalImage, [], mock_plugin_info_2, mock_plugin_2, dataset_uid_1, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.name, results_2.name), 'Expected result');
            obj.Assert(strcmp(output_image.Title, image_2.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info_2), 'Expected run output');

            % Test saving an edited version of this result
            edited_image_2 = PTKImage;
            edited_image_2.Title = 'Edited Image 2';
            context_hierarchy.SaveEditedResult(plugin_2, PTKContext.OriginalImage, edited_image_2, mock_plugin_info_2, [], dataset_uid_1, mock_reporting);            
            saved_edited_result = mock_dependency_tracker.SavedMockResults([plugin_2 '.' char(PTKContext.OriginalImage) '.' dataset_uid_1]);
            obj.Assert(strcmp(saved_edited_result.Title, edited_image_2.Title), 'Expected image');
            
        end

        
        
        function TestExtractROIFromOriginalImage(obj)
            % Test 2: test extracting an ROI region from the full lung
            
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

            image_template_2 = image_2.BlankCopy;
            image_template_2.Title = 'Template for OriginalImage';
                        
            mock_plugin = MockPlugin;

            image_template_l = image_2.Copy;
            image_template_l.Crop([2,2,2], [7,7,7]);
            image_template_l = image_template_l.BlankCopy;
            image_template_l.Title = 'Template for ROI';
            
            mock_image_templates.AddMockImage(PTKContext.OriginalImage, image_template_2);
            mock_image_templates.AddMockImage(PTKContext.LungROI, image_template_l);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin_2, PTKContext.LungROI, [], mock_plugin_info_2, mock_plugin, dataset_uid_2, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.name, results_2.name), 'Expected result');
            obj.Assert(strcmp(output_image.Title, image_2.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info_2), 'Expected run output');
            obj.Assert(isequal(output_image.ImageSize, [6 6 6]), 'Image has been cropped');
            
            
            % Test saving an edited version of this result with LungROI context,
            % and see that it is correctly inserted into the OriginalImage
            edited_image_1 = output_image.Copy;
            edited_image_1.ChangeRawImage(edited_image_1.RawImage + 10);
            edited_image_1.Title = 'Edited Image 1';
            context_hierarchy.SaveEditedResult(plugin_2, PTKContext.LungROI, edited_image_1, mock_plugin_info_2, [], dataset_uid_2, mock_reporting);
            saved_edited_result_oi = mock_dependency_tracker.SavedMockResults([plugin_2 '.' char(PTKContext.OriginalImage) '.' dataset_uid_2]);
            obj.Assert(strcmp(saved_edited_result_oi.Title, edited_image_1.Title), 'Expected image');
            obj.Assert(isequal(saved_edited_result_oi.ImageSize, image_2.ImageSize), 'Image has been resized');
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
            
            % Create template for both lungs
            template_lungs = template_roi.BlankCopy;
            template_lungs.ChangeRawImage(mock_lr_lung_image_raw > 0);
            template_lungs.Title = 'TemplateLungs';
            
            % Create templates for left and right lungs
            template_right = mock_roi_image.BlankCopy;
            template_right.ChangeRawImage(mock_lr_lung_image_raw_r);
            template_left = mock_roi_image.BlankCopy;
            template_left.ChangeRawImage(mock_lr_lung_image_raw_l);
            
            % Add templates to the template class
            mock_image_templates.AddMockImage(PTKContext.OriginalImage, template_original);
            mock_image_templates.AddMockImage(PTKContext.LungROI, template_roi);
            mock_image_templates.AddMockImage(PTKContext.Lungs, template_lungs);
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
            mock_plugin_info3.Context = PTKContextSet.Lungs;
            mock_plugin_info3.PluginType = 'ReplaceOverlay';
            
            plugin4 = 'Plugin4';
            mock_plugin_info4 = [];
            mock_plugin_info4.GeneratePreview = true;
            mock_plugin_info4.Context = PTKContextSet.SingleLung;
            mock_plugin_info4.PluginType = 'ReplaceOverlay';
            
            plugin5 = 'Plugin5';
            mock_plugin_info5 = [];
            mock_plugin_info5.GeneratePreview = true;
            mock_plugin_info5.Context = PTKContextSet.SingleLung;
            mock_plugin_info5.PluginType = 'ReplaceOverlay';
            
            
            results = mock_roi_image.Copy;
            results_original = mock_original_image.Copy;
            
            left_image = template_left.Copy;
            left_image.ChangeRawImage(uint8(left_image.RawImage).*uint8(mock_roi_image.RawImage));
            left_image.Title = 'LeftResultImage';
            right_image = template_right.Copy;
            right_image.ChangeRawImage(uint8(right_image.RawImage).*uint8(mock_roi_image.RawImage));
            right_image.Title = 'RightResultImage';
            
            mock_dependency_tracker.AddMockResult(plugin, PTKContext.LungROI, dataset_uid, results, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin2, PTKContext.OriginalImage, dataset_uid, results_original, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin3, PTKContext.Lungs, dataset_uid, results_original, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.LeftLung, dataset_uid, left_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.RightLung, dataset_uid, right_image, cache_info_input, true);
            
            composite_result_l = [];
            composite_result_l.Result = 'left';
            composite_result_l.ImageResult = left_image;
            
            composite_result_r = [];
            composite_result_r.Result = 'right';
            composite_result_r.ImageResult = right_image;
            
            
            mock_dependency_tracker.AddMockResult(plugin5, PTKContext.LeftLung, dataset_uid, composite_result_l, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5, PTKContext.RightLung, dataset_uid, composite_result_r, cache_info_input, true);

            mock_plugin = MockPlugin;
            mock_plugin2 = MockPlugin;
            mock_plugin3 = MockPlugin;
            mock_plugin4 = MockPlugin;
            mock_plugin5 = MockPlugin;
            

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
            
            % Fetch a result for the lungs from a plugin that has a
            % LungROI context set            
            result = context_hierarchy.GetResult(plugin, PTKContext.Lungs, [], mock_plugin_info, mock_plugin, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.Lungs, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image.RawImage & mock_roi_image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image.RawImage & mock_roi_image.RawImage)), 'Image is correct ROI');
            
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
            
            % Fetch a result for the right lung from a plugin that has a
            % Lungs context set
            result = context_hierarchy.GetResult(plugin3, PTKContext.RightLung, [], mock_plugin_info3, mock_plugin3, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin3, PTKContext.RightLung, [], mock_plugin_info3, mock_plugin2, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_r & original_image_cropped.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_r & original_image_cropped.RawImage)), 'Image is correct ROI');
            
            
            % Fetch a result for the original image from a plugin that has a
            % SingleLung context set (where the result is an image)
            result = context_hierarchy.GetResult(plugin4, PTKContext.OriginalImage, [], mock_plugin_info4, mock_plugin4, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin4, PTKContext.OriginalImage, [], mock_plugin_info4, mock_plugin4, dataset_uid, [], force_generate_image, false, mock_reporting);
            
            expected_output_image = mock_lr_lung_image.Copy;
            expected_output_image.ChangeRawImage((expected_output_image.RawImage > 0) & mock_roi_image.RawImage);
            expected_output_image.ResizeToMatch(mock_original_image);
            obj.Assert(isequal(result.RawImage, expected_output_image.RawImage), 'Expected output image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung, cache_info_input), 'Expected run output');
            
            % Fetch a result for the original image from a plugin that has a
            % SingleLung context set (where the result is a composite)
            result = context_hierarchy.GetResult(plugin5, PTKContext.OriginalImage, [], mock_plugin_info5, mock_plugin5, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin5, PTKContext.OriginalImage, [], mock_plugin_info5, mock_plugin5, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.LungROI.Lungs.LeftLung.Result, 'left'), 'Expected result');
            obj.Assert(isequal(output_image.ImageSize, mock_original_image.ImageSize), 'Expected result image size');
            obj.Assert(strcmp(result.LungROI.Lungs.RightLung.Result, 'right'), 'Expected result');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung, cache_info_input), 'Expected run output');
            obj.Assert(isequal(result.LungROI.Lungs.LeftLung.ImageResult.RawImage, left_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.Lungs.RightLung.ImageResult.RawImage, right_image.RawImage), 'Image is correct ROI');
            
            expected_output_image = mock_lr_lung_image.Copy;
            expected_output_image.ChangeRawImage((expected_output_image.RawImage > 0) & mock_roi_image.RawImage);
            expected_output_image.ResizeToMatch(mock_original_image);            
            obj.Assert(isequal(output_image.RawImage, expected_output_image.RawImage), 'Expected output image');
                        
            expected_output_image = mock_original_image.Copy;
            expected_output_image.Clear;
            expected_output_image.ChangeSubImageWithMask(left_image, template_left);
            expected_output_image.ChangeSubImageWithMask(right_image, template_right);
            obj.Assert(isequal(output_image.RawImage, expected_output_image.RawImage), 'Image is correct ROI');
            
            
            
        end
        
        function TestExtractLobes(obj)
            % Test 4: test extracting lobes, and concatenating
            % images to a higher context
            
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
            
            % Create template for both lungs
            template_lungs = template_roi.BlankCopy;
            template_lungs.ChangeRawImage(mock_lr_lung_image_raw > 0);
            template_lungs.Title = 'TemplateLungs';
            
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
            template_lungs.CropToFit;
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
            mock_image_templates.AddMockImage(PTKContext.Lungs, template_lungs);
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
            mock_plugin_info3.Context = PTKContextSet.Lungs;
            mock_plugin_info3.PluginType = 'ReplaceOverlay';
            
            plugin4 = 'Plugin4';
            mock_plugin_info4 = [];
            mock_plugin_info4.GeneratePreview = true;
            mock_plugin_info4.Context = PTKContextSet.SingleLung;
            mock_plugin_info4.PluginType = 'ReplaceOverlay';
            
            plugin4c = 'Plugin4_combined';
            mock_plugin_info4c = [];
            mock_plugin_info4c.GeneratePreview = true;
            mock_plugin_info4c.Context = PTKContextSet.SingleLung;
            mock_plugin_info4c.PluginType = 'ReplaceOverlay';

            plugin5 = 'Plugin5';
            mock_plugin_info5 = [];
            mock_plugin_info5.GeneratePreview = true;
            mock_plugin_info5.Context = PTKContextSet.Lobe;
            mock_plugin_info5.PluginType = 'ReplaceOverlay';
            
            plugin5c = 'Plugin5c';
            mock_plugin_info5c = [];
            mock_plugin_info5c.GeneratePreview = true;
            mock_plugin_info5c.Context = PTKContextSet.Lobe;
            mock_plugin_info5c.PluginType = 'ReplaceOverlay';

            results = mock_roi_image.Copy;
            results_original = mock_original_image.Copy;
            
            lungs_image = template_lungs.Copy;
            lungs_image.ChangeRawImage(uint8(lungs_image.RawImage).*uint8(rand(lungs_image.ImageSize) > 0.5));
            lungs_image.Title = 'LungsResultImage';
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
            mock_dependency_tracker.AddMockResult(plugin3, PTKContext.Lungs, dataset_uid, lungs_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.LeftLung, dataset_uid, left_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4, PTKContext.RightLung, dataset_uid, right_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4c, PTKContext.LeftLung, dataset_uid, struct('Result', 'left', 'ImageResult', left_image), cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin4c, PTKContext.RightLung, dataset_uid, struct('Result', 'left', 'ImageResult', right_image), cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5, PTKContext.RightUpperLobe, dataset_uid, ru_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5, PTKContext.RightMiddleLobe, dataset_uid, rm_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5, PTKContext.RightLowerLobe, dataset_uid, rl_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5, PTKContext.LeftUpperLobe, dataset_uid, lu_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5, PTKContext.LeftLowerLobe, dataset_uid, ll_image, cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5c, PTKContext.RightUpperLobe, dataset_uid, struct('Result', 'left', 'ImageResult', ru_image), cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5c, PTKContext.RightMiddleLobe, dataset_uid, struct('Result', 'left', 'ImageResult', rm_image), cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5c, PTKContext.RightLowerLobe, dataset_uid, struct('Result', 'left', 'ImageResult', rl_image), cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5c, PTKContext.LeftUpperLobe, dataset_uid, struct('Result', 'left', 'ImageResult', lu_image), cache_info_input, true);
            mock_dependency_tracker.AddMockResult(plugin5c, PTKContext.LeftLowerLobe, dataset_uid, struct('Result', 'left', 'ImageResult', ll_image), cache_info_input, true);

            mock_plugin = MockPlugin;
            mock_plugin2 = MockPlugin;
            mock_plugin3 = MockPlugin;
            mock_plugin4 = MockPlugin;
            mock_plugin4c = MockPlugin;
            mock_plugin5 = MockPlugin;
            mock_plugin5c = MockPlugin;
            

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
            
            % Test saving an edited version of this result with RightLung context,
            % and see that it is correctly inserted into the OriginalImage
            edited_image_1 = output_image.Copy;
            edited_image_1.ChangeRawImage(edited_image_1.RawImage + 10);
            edited_image_1.Title = 'Edited Image 1';
            context_hierarchy.SaveEditedResult(plugin, PTKContext.RightLung, edited_image_1, mock_plugin_info, [], dataset_uid, mock_reporting);
            saved_edited_result_oi = mock_dependency_tracker.SavedMockResults([plugin '.' char(PTKContext.LungROI) '.' dataset_uid]);
            obj.Assert(strcmp(saved_edited_result_oi.Title, edited_image_1.Title), 'Expected image');
            obj.Assert(isequal(saved_edited_result_oi.ImageSize, mock_roi_image.ImageSize), 'Image has been resized');

            
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
            % context set (for image results)
            result = context_hierarchy.GetResult(plugin4, PTKContext.OriginalImage, [], mock_plugin_info4, mock_plugin4, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin4, PTKContext.OriginalImage, [], mock_plugin_info4, mock_plugin4, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung, cache_info_input), 'Expected run output');

            expected_output_image = mock_original_image.Copy;
            expected_output_image.Clear;
            expected_output_image.ChangeSubImageWithMask(left_image, template_left);
            expected_output_image.ChangeSubImageWithMask(right_image, template_right);
            obj.Assert(isequal(output_image.RawImage, expected_output_image.RawImage), 'Image is correct ROI');


            % Fetch a result for the whole lung from a plugin with a lung
            % context set (for composite results)
            result = context_hierarchy.GetResult(plugin4c, PTKContext.OriginalImage, [], mock_plugin_info4c, mock_plugin4c, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin4c, PTKContext.OriginalImage, [], mock_plugin_info4c, mock_plugin4c, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.LungROI.Lungs.LeftLung.ImageResult.Title, left_image.Title), 'Expected result');
            obj.Assert(strcmp(result.LungROI.Lungs.RightLung.ImageResult.Title, right_image.Title), 'Expected result');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung, cache_info_input), 'Expected run output');
            obj.Assert(isequal(result.LungROI.Lungs.LeftLung.ImageResult.RawImage, left_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.Lungs.RightLung.ImageResult.RawImage, right_image.RawImage), 'Image is correct ROI');
            
            
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
            % context set (for image results)
            result = context_hierarchy.GetResult(plugin5, PTKContext.OriginalImage, [], mock_plugin_info5, mock_plugin5, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin5, PTKContext.OriginalImage, [], mock_plugin_info5, mock_plugin5, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung.LeftUpperLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung.LeftLowerLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung.RightUpperLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung.RightMiddleLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung.RightLowerLobe, cache_info_input), 'Expected run output');

            expected_output_image = mock_original_image.Copy;
            expected_output_image.Clear;
            expected_output_image.ChangeSubImageWithMask(lu_image, template_lu);
            expected_output_image.ChangeSubImageWithMask(ll_image, template_ll);
            expected_output_image.ChangeSubImageWithMask(ru_image, template_ru);
            expected_output_image.ChangeSubImageWithMask(rm_image, template_rm);
            expected_output_image.ChangeSubImageWithMask(rl_image, template_rl);
            obj.Assert(isequal(output_image.RawImage, expected_output_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.RawImage, expected_output_image.RawImage), 'Image is correct ROI');


            % Fetch a result for the whole lung from a plugin with a lobe
            % context set (for composite results)
            result = context_hierarchy.GetResult(plugin5c, PTKContext.OriginalImage, [], mock_plugin_info5c, mock_plugin5, dataset_uid, [], false, false, mock_reporting);
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin5c, PTKContext.OriginalImage, [], mock_plugin_info5c, mock_plugin5c, dataset_uid, [], force_generate_image, false, mock_reporting);
            obj.Assert(strcmp(result.LungROI.Lungs.LeftLung.LeftUpperLobe.ImageResult.Title, lu_image.Title), 'Expected result');
            obj.Assert(strcmp(result.LungROI.Lungs.RightLung.RightUpperLobe.ImageResult.Title, ru_image.Title), 'Expected result');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung.LeftUpperLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.LeftLung.LeftLowerLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung.RightUpperLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung.RightMiddleLobe, cache_info_input), 'Expected run output');
            obj.Assert(strcmp(cache_info.LungROI.Lungs.RightLung.RightLowerLobe, cache_info_input), 'Expected run output');
            obj.Assert(isequal(result.LungROI.Lungs.LeftLung.LeftUpperLobe.ImageResult.RawImage, lu_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.Lungs.LeftLung.LeftLowerLobe.ImageResult.RawImage, ll_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.Lungs.RightLung.RightUpperLobe.ImageResult.RawImage, ru_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.Lungs.RightLung.RightMiddleLobe.ImageResult.RawImage, rm_image.RawImage), 'Image is correct ROI');
            obj.Assert(isequal(result.LungROI.Lungs.RightLung.RightLowerLobe.ImageResult.RawImage, rl_image.RawImage), 'Image is correct ROI');

            expected_output_image = mock_original_image.Copy;
            expected_output_image.Clear;
            expected_output_image.ChangeSubImageWithMask(lu_image, template_lu);
            expected_output_image.ChangeSubImageWithMask(ll_image, template_ll);
            expected_output_image.ChangeSubImageWithMask(ru_image, template_ru);
            expected_output_image.ChangeSubImageWithMask(rm_image, template_rm);
            expected_output_image.ChangeSubImageWithMask(rl_image, template_rl);
            obj.Assert(isequal(output_image.RawImage, expected_output_image.RawImage), 'Image is correct ROI');

            % Test saving an edited version of this result
            edited_image_2 = output_image.Copy;
            edited_image_2.ChangeRawImage(edited_image_2.RawImage + 10);            
            edited_image_2.Title = 'Edited Image 2';
            context_hierarchy.SaveEditedResult(plugin5, PTKContext.LungROI, edited_image_2, mock_plugin_info5, [], dataset_uid, mock_reporting);
            saved_edited_result_lu = mock_dependency_tracker.SavedMockResults([plugin5 '.' char(PTKContext.LeftUpperLobe) '.' dataset_uid]);
            saved_edited_result_ll = mock_dependency_tracker.SavedMockResults([plugin5 '.' char(PTKContext.LeftLowerLobe) '.' dataset_uid]);
            saved_edited_result_ru = mock_dependency_tracker.SavedMockResults([plugin5 '.' char(PTKContext.RightUpperLobe) '.' dataset_uid]);
            saved_edited_result_rm = mock_dependency_tracker.SavedMockResults([plugin5 '.' char(PTKContext.RightMiddleLobe) '.' dataset_uid]);
            saved_edited_result_rl = mock_dependency_tracker.SavedMockResults([plugin5 '.' char(PTKContext.RightLowerLobe) '.' dataset_uid]);
            
            expected_result_lu = edited_image_2.Copy;
            expected_result_lu.ResizeToMatch(lu_image);
            expected_result_lu.ChangeRawImage(expected_result_lu.RawImage .* uint8(template_lu.RawImage> 0));
            obj.Assert(isequal(saved_edited_result_lu.RawImage, expected_result_lu.RawImage), 'Image is correct ROI');

            expected_result_ru = edited_image_2.Copy;
            expected_result_ru.ResizeToMatch(ru_image);
            expected_result_ru.ChangeRawImage(expected_result_ru.RawImage .* uint8(template_ru.RawImage> 0));
            obj.Assert(isequal(saved_edited_result_ru.RawImage, expected_result_ru.RawImage), 'Image is correct ROI');

            expected_result_ll = edited_image_2.Copy;
            expected_result_ll.ResizeToMatch(ll_image);
            expected_result_ll.ChangeRawImage(expected_result_ll.RawImage .* uint8(template_ll.RawImage> 0));
            obj.Assert(isequal(saved_edited_result_ll.RawImage, expected_result_ll.RawImage), 'Image is correct ROI');

            expected_result_rl = edited_image_2.Copy;
            expected_result_rl.ResizeToMatch(rl_image);
            expected_result_rl.ChangeRawImage(expected_result_rl.RawImage .* uint8(template_rl.RawImage> 0));
            obj.Assert(isequal(saved_edited_result_rl.RawImage, expected_result_rl.RawImage), 'Image is correct ROI');

            expected_result_rm = edited_image_2.Copy;
            expected_result_rm.ResizeToMatch(rm_image);
            expected_result_rm.ChangeRawImage(expected_result_rm.RawImage .* uint8(template_rm.RawImage> 0));
            obj.Assert(isequal(saved_edited_result_rm.RawImage, expected_result_rm.RawImage), 'Image is correct ROI');
            
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

