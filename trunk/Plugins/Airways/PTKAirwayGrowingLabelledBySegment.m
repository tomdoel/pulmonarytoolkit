classdef PTKAirwayGrowingLabelledBySegment < PTKPlugin
    % PTKAirwayGrowingLabelledBySegment. Plugin to find the segmental bronchi in each lobe
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
 
    properties
        ButtonText = 'Growing bronchi<br>labelled by segment'
        ToolTip = 'Finds the segmental bronchi in each lobe'
        Category = 'Synergy'
 
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            growing_centreline_tree = dataset.GetResult('PTKAirwayGrowing');
            growing_centreline_tree = growing_centreline_tree.Airways;
            
            segments_by_bronchus = dataset.GetResult('PTKSegmentsByNearestBronchus');
            
            labelled_segmental_tree = segments_by_bronchus.AirwaysBySegment.Trachea;
            
            growing_tree_with_segmental_labels = PTKMapSegmentalParameters(labelled_segmental_tree, growing_centreline_tree, reporting);

            results = [];
            results.StartBranches = growing_tree_with_segmental_labels;
        end
    end 
end