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
            obj.TestExtractLeftLung;
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
        
        % Test 3: test extracting left lung image
        function TestExtractLeftLung(obj)
            mock_reporting = MockReporting;
            mock_dependency_tracker = MockPluginDependencyTracker;
            mock_image_templates = MockImageTemplates;            
            context_hierarchy = PTKContextHierarchy(mock_dependency_tracker, mock_image_templates, mock_reporting);
            
            
            mock_lr_lung_image_raw = false(10,10,10);
            mock_lr_lung_image_raw_r = mock_lr_lung_image_raw;
            mock_lr_lung_image_raw_r(2:8, 1:3, 2:9) = true;
            mock_lr_lung_image_raw_l = mock_lr_lung_image_raw;
            mock_lr_lung_image_raw_l(3:9, 6:8, 3:9) = true;
            mock_lr_lung_image_raw = uint8(mock_lr_lung_image_raw_r) + 2*uint8(mock_lr_lung_image_raw_l);
            
            mock_lr_lung_image_r = PTKImage(mock_lr_lung_image_raw_r);
            mock_lr_lung_image_l = PTKImage(mock_lr_lung_image_raw_l);
            mock_lr_lung_image = PTKImage(mock_lr_lung_image_raw);
            
            
            cache_info = 'Cache Info';
            plugin = 'Plugin';
            dataset_uid = '789';
            
            force_generate_image = true;
            mock_plugin_info = [];
            mock_plugin_info.GeneratePreview = true;
            mock_plugin_info.Context = PTKContextSet.LungROI;
            
            image = PTKImage(uint8(rand(10,10,10) > 0.5));
            image.Title = 'ResultImage';
            
            results = image;
            mock_dependency_tracker.AddMockResult(plugin, PTKContext.LungROI, dataset_uid, results, cache_info, true);

            mock_plugin = MockPlugin;
            

            mock_image_templates.AddMockImage(PTKContext.LungROI, mock_lr_lung_image.BlankCopy);
            mock_image_templates.AddMockImage(PTKContext.LeftLung, mock_lr_lung_image_l);
            mock_image_templates.AddMockImage(PTKContext.RightLung, mock_lr_lung_image_r);

            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LungROI, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.LeftLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_l & image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_l & image.RawImage)), 'Image is correct ROI');
            
            [result, output_image, plugin_has_been_run, cache_info] = context_hierarchy.GetResult(plugin, PTKContext.RightLung, [], mock_plugin_info, mock_plugin, dataset_uid, [], force_generate_image, mock_reporting);
            obj.Assert(strcmp(result.Title, results.Title), 'Expected result');
            obj.Assert(strcmp(output_image.Title, image.Title), 'Expected image');
            obj.Assert(plugin_has_been_run == true, 'Expected run output');
            obj.Assert(strcmp(cache_info, cache_info), 'Expected run output');
            obj.Assert(isequal(result.RawImage, uint8(mock_lr_lung_image_raw_r & image.RawImage)), 'Image is correct ROI');
            obj.Assert(isequal(output_image.RawImage, uint8(mock_lr_lung_image_raw_r & image.RawImage)), 'Image is correct ROI');
            
        end
    end    
end

