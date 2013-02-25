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
            
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin_1, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid_1, [], force_generate_image, mock_reporting);
            
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
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin_2, PTKContext.LungROI, [], mock_plugin_info_2, mock_plugin, dataset_uid_2, [], force_generate_image, mock_reporting);
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
            
            plugin2 = 'Plugin2';
            mock_plugin_info2 = [];
            mock_plugin_info2.GeneratePreview = true;
            mock_plugin_info2.Context = PTKContextSet.OriginalImage;

            plugin3 = 'Plugin3';
            mock_plugin_info3 = [];
            mock_plugin_info3.GeneratePreview = true;
            mock_plugin_info3.Context = PTKContextSet.SingleLung;

            
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
            

            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            
            % Fetch a result for the left lung from a plugin that has a
            % LungROI context set            
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LeftLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_l & mock_roi_image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_l & mock_roi_image.RawImage)), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has a
            % LungROI context set            
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.RightLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_roi_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_r & mock_roi_image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_r & mock_roi_image.RawImage)), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has an
            % OriginalImage context set
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin2, PTKContext.RightLung, [], mock_plugin_info2, mock_plugin2, dataset_uid, [], force_generate_image, mock_reporting);
            obj.Assert(strcmp(result.Title, results_original.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, mock_original_image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_r & original_image_cropped.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_r & original_image_cropped.RawImage)), 'Image is correct ROI');
            
            % Fetch a result for the right lung from a plugin that has an
            % OriginalImage context set
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin3, PTKContext.OriginalImage, [], mock_plugin_info3, mock_plugin3, dataset_uid, [], force_generate_image, mock_reporting);
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
    end    
end

