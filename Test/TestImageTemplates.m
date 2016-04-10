classdef TestImageTemplates < CoreTest
    % TestImageTemplates. Tests for the MimImageTemplates class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestImageTemplates
            
            mock_reporting = CoreMockReporting;
            mock_datset_disk_cache = MockDatasetDiskCache;
            mock_dataset_results = MockDatasetResults;
            context_def = PTKContextDef;
            image_templates = MimImageTemplates(mock_dataset_results, context_def, mock_datset_disk_cache, mock_reporting);
            mock_dataset_results.ImageTemplates = image_templates;
            null_dataset_stack = [];
            
            
            
            % By default, all contexts should be enabled
            obj.Assert(image_templates.IsContextEnabled(PTKContext.OriginalImage), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LungROI), 'ROI context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightMiddleLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLowerLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftLowerLobe), 'Context is enabled');
            
            
            
            
            % Check that code fails where template could not be generated
            % When asking for a template, the code should fail if the template
            % could not be generated
            mock_dataset_results.AddMockResult('PTKOriginalImage', PTKContext.OriginalImage, [], [], [], true);
            mock_reporting.AddExpectation('CoreMockReporting.Error', 'MimImageTemplates:NoContext');
            try
                template_image = image_templates.GetTemplateImage(PTKContext.OriginalImage, null_dataset_stack, mock_reporting);
            catch ex
                if ~isa(ex, 'CoreTestException')
                    CoreErrorUtilities.ThrowException('TestImageTemplates:WrongException', 'Test failure: test exception expected');
                    
                end
            end
            
            % Due to the failure, the original image context should now be
            % disabled
            obj.Assert(~image_templates.IsContextEnabled(PTKContext.OriginalImage), 'Context is disabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LungROI), 'ROI context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightMiddleLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLowerLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftLowerLobe), 'Context is enabled');
            
            
            % Now force a failure for two more contexts (LungROI and LeftLung,
            % leaving RightLung enabled)
            
            mock_dataset_results.AddMockResult('PTKLungROI', PTKContext.LungROI, [], [], [], true);
            mock_reporting.AddExpectation('CoreMockReporting.Error', 'MimImageTemplates:NoContext');
            try
                template_image = image_templates.GetTemplateImage(PTKContext.LungROI, null_dataset_stack, mock_reporting);
            catch ex
                if ~isa(ex, 'CoreTestException')
                    CoreErrorUtilities.ThrowException('TestImageTemplates:WrongException', 'Test failure: test exception expected');
                    
                end
            end
            mock_dataset_results.AddMockResult('PTKGetContextForSingleLung', PTKContext.LeftLung, [], [], [], true);
            mock_reporting.AddExpectation('CoreMockReporting.Error', 'MimImageTemplates:NoContext');
            try
                template_image = image_templates.GetTemplateImage(PTKContext.LeftLung, null_dataset_stack, mock_reporting);
            catch ex
                if ~isa(ex, 'CoreTestException')
                    CoreErrorUtilities.ThrowException('TestImageTemplates:WrongException', 'Test failure: test exception expected');
                    
                end
            end
            
            
            % Now three of the contexts should be disbaled
            obj.Assert(~image_templates.IsContextEnabled(PTKContext.OriginalImage), 'Context is disabled');
            obj.Assert(~image_templates.IsContextEnabled(PTKContext.LungROI), 'ROI context is enabled');
            obj.Assert(~image_templates.IsContextEnabled(PTKContext.LeftLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightMiddleLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLowerLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftLowerLobe), 'Context is enabled');

            
            
            % Check normal accessing of templates
            
            % Add template image results 
            mock_roi_image = PTKImage;
            mock_roi_image.Title = 'roi';
            mock_full_image = PTKImage;
            mock_full_image.Title = 'full';
            mock_left_image = PTKImage;
            mock_left_image.Title = 'left';
            mock_right_image = PTKImage;
            mock_right_image.Title = 'right';
            mock_ru_image = PTKImage;
            mock_ru_image.Title = 'ru';
            mock_rm_image = PTKImage;
            mock_rm_image.Title = 'rm';
            mock_rl_image = PTKImage;
            mock_rl_image.Title = 'rl';
            mock_lu_image = PTKImage;
            mock_lu_image.Title = 'lu';
            mock_ll_image = PTKImage;
            mock_ll_image.Title = 'll';
            
            lung_roi_cache_item = MimDatasetStackItem(PTKDependency('PTKLungROI', PTKContext.LungROI, '1.2.3.4.5', '1', []), MimDependencyList, false, false, mock_reporting);
            oi_cache_item = MimDatasetStackItem(PTKDependency('PTKOriginalImage', PTKContext.OriginalImage, '1.2.3.4.6', '1', []), MimDependencyList, false, false, mock_reporting);
            ll_cache_item = MimDatasetStackItem(PTKDependency('PTKGetContextForSingleLung', PTKContext.LeftLung, '1.2.3.4.7', '1', []), MimDependencyList, false, false, mock_reporting);
            rl_cache_item = MimDatasetStackItem(PTKDependency('PTKGetContextForSingleLung', PTKContext.RightLung, '1.2.3.4.8', '1', []), MimDependencyList, false, false, mock_reporting);
            rul_cache_item = MimDatasetStackItem(PTKDependency('PTKGetContextForLobe', PTKContext.RightUpperLobe, '1.2.3.4.9', '1', []), MimDependencyList, false, false, mock_reporting);
            rml_cache_item = MimDatasetStackItem(PTKDependency('PTKGetContextForLobe', PTKContext.RightMiddleLobe, '1.2.3.4.10', '1', []), MimDependencyList, false, false, mock_reporting);
            rll_cache_item = MimDatasetStackItem(PTKDependency('PTKGetContextForLobe', PTKContext.RightLowerLobe, '1.2.3.4.11', '1', []), MimDependencyList, false, false, mock_reporting);
            lul_cache_item = MimDatasetStackItem(PTKDependency('PTKGetContextForLobe', PTKContext.LeftUpperLobe, '1.2.3.4.12', '1', []), MimDependencyList, false, false, mock_reporting);
            lll_cache_item = MimDatasetStackItem(PTKDependency('PTKGetContextForLobe', PTKContext.LeftLowerLobe, '1.2.3.4.13', '1', []), MimDependencyList, false, false, mock_reporting);
            
            % Check fetching the template images
            mock_dataset_results.AddMockResult('PTKLungROI', PTKContext.LungROI, mock_roi_image, lung_roi_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKOriginalImage', PTKContext.OriginalImage, mock_full_image, oi_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKGetContextForSingleLung', PTKContext.LeftLung, mock_left_image, ll_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKGetContextForSingleLung', PTKContext.RightLung, mock_right_image, rl_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKGetContextForLobe', PTKContext.RightUpperLobe, mock_ru_image, rul_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKGetContextForLobe', PTKContext.RightMiddleLobe, mock_rm_image, rml_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKGetContextForLobe', PTKContext.RightLowerLobe, mock_rl_image, rll_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKGetContextForLobe', PTKContext.LeftUpperLobe, mock_lu_image, lul_cache_item, [], true);
            mock_dataset_results.AddMockResult('PTKGetContextForLobe', PTKContext.LeftLowerLobe, mock_ll_image, lll_cache_item, [], true);

            roi_template_image = image_templates.GetTemplateImage(PTKContext.LungROI, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(roi_template_image.Title, 'roi'), 'Correct template image returned');

            original_template_image = image_templates.GetTemplateImage(PTKContext.OriginalImage, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(original_template_image.Title, 'full'), 'Correct template image returned');
           
            left_template_image = image_templates.GetTemplateImage(PTKContext.LeftLung, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(left_template_image.Title, 'left'), 'Correct template image returned');

            right_template_image = image_templates.GetTemplateImage(PTKContext.RightLung, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(right_template_image.Title, 'right'), 'Correct template image returned');

            ru_template_image = image_templates.GetTemplateImage(PTKContext.RightUpperLobe, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(ru_template_image.Title, 'ru'), 'Correct template image returned');

            rm_template_image = image_templates.GetTemplateImage(PTKContext.RightMiddleLobe, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(rm_template_image.Title, 'rm'), 'Correct template image returned');
            
            rl_template_image = image_templates.GetTemplateImage(PTKContext.RightLowerLobe, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(rl_template_image.Title, 'rl'), 'Correct template image returned');
            
            lu_template_image = image_templates.GetTemplateImage(PTKContext.LeftUpperLobe, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(lu_template_image.Title, 'lu'), 'Correct template image returned');

            ll_template_image = image_templates.GetTemplateImage(PTKContext.LeftLowerLobe, null_dataset_stack, mock_reporting);
            obj.Assert(strcmp(ll_template_image.Title, 'll'), 'Correct template image returned');
            
            % Contexts should now all be enabled again
            obj.Assert(image_templates.IsContextEnabled(PTKContext.OriginalImage), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LungROI), 'ROI context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLung), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightMiddleLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.RightLowerLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftUpperLobe), 'Context is enabled');
            obj.Assert(image_templates.IsContextEnabled(PTKContext.LeftLowerLobe), 'Context is enabled');
        end
    end    
end

