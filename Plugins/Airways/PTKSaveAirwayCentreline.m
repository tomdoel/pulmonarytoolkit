classdef PTKSaveAirwayCentreline < PTKPlugin
    % PTKSaveAirwayCentreline. Plugin for saving a model of the segmented
    % airway tree as node/elem files
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties
        ButtonText = 'Export airway<br>centreline'
        ToolTip = 'Saves the '
        Category = 'Airways'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            
            [~, template_image] = dataset.GetResult('PTKAirways');
            results = template_image;
            
            starting_segment = dataset.GetResult('PTKAirwayCentreline');
            starting_segment = starting_segment.AirwayCentrelineTree;
            starting_segment.GenerateBranchParameters;
            
            % Get the results directory
            path_base = dataset.GetOutputPathAndCreateIfNecessary;
            file_path = fullfile(path_base, 'AirwayTree');
            PTKDiskUtilities.CreateDirectoryIfNecessary(file_path);
            
            coordinate_system = PTKCoordinateSystem.DicomUntranslated;
            
            centreline_tree_filename_prefix = 'AirwayTree_Centreline';
            PTKSaveCentrelineTreeAsNodes(starting_segment, file_path, centreline_tree_filename_prefix, coordinate_system, template_image, reporting)
            dataset.RecordNewFileAdded('PTKSaveAirwayCentreline', file_path, centreline_tree_filename_prefix, 'Centreline model of the airwya tree down to the segmental bronchi, constructed from the segmented airway tree.');
            
            airway_tree_filename_prefix = 'AirwayTree_Model';            
            PTKSaveTreeAsNodes(starting_segment, file_path, airway_tree_filename_prefix, coordinate_system, template_image, reporting)    
            dataset.RecordNewFileAdded('PTKSaveAirwayCentreline', file_path, airway_tree_filename_prefix, 'Model of the airwya tree down to the segmental bronchi, constructed from the segmented airway tree.');

            % Save the smoothed airway centreline
            airway_tree_filename_prefix = 'AirwayTree_SmoothedCentreline';            
            PTKSaveSmoothedCentrelineTreeAsNodes(starting_segment, file_path, airway_tree_filename_prefix, coordinate_system, template_image, reporting);
            dataset.RecordNewFileAdded('PTKSaveAirwayCentreline', file_path, airway_tree_filename_prefix, 'Smoothed centreline model of the airway tree, constructed from the segmented airway tree.');            
            
            try
                % Get the pruned airway centreline
                starting_segment_pruned = dataset.GetResult('PTKAirwaysPrunedBySegment');
                results = starting_segment_pruned.PrunedSegmentsByLobeImage;
                template_image = results;
                
                % Save the pruned, smoothed airway centreline
                starting_segment_pruned = starting_segment_pruned.StartBranches.Trachea;
                starting_segment_pruned.GenerateBranchParameters;
                
                airway_tree_filename_prefix = 'AirwayTree_PrunedSmoothedCentreline';
                PTKSaveSmoothedCentrelineTreeAsNodes(starting_segment_pruned, file_path, airway_tree_filename_prefix, coordinate_system, template_image, reporting);
                dataset.RecordNewFileAdded('PTKSaveAirwayCentreline', file_path, airway_tree_filename_prefix, 'Smoothed centreline model of the airway tree down to the segmental bronchi, constructed from the segmented airway tree.');
            catch exception
                reporting.ShowMessage('PTKSaveAirwayCentreline:CouldNotComputePrunedAirways', ['Warning: The pruned airway centrelines will not be saved for this dataset as the pulmonary segments could not be found due to the following error:.' exception.message]);
            end
        end
        
        function results = GenerateImageFromResults(results, image_templates, reporting)
        end        
    end
end