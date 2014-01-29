classdef PTKSegmentsByNearestBronchus < PTKPlugin
    % PTKSegmentsByNearestBronchus. Plugin for approximating the pulmonary
    % segments
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Segments <BR>(nearest bronchus)'
        ToolTip = 'Approximation for the pulmonary segments based on the nearest bronchus'
        Category = 'Segments'
        
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            airway_results = dataset.GetResult('PTKAirways');
            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungs');
            segmental_bronchi_for_lobes = dataset.GetResult('PTKSegmentalBronchi');
            lobes = dataset.GetResult('PTKLobesFromFissurePlane');
            [segment_image_map, labelled_segments] = PTKGetSegmentsByNearestBronchus(airway_results.AirwayTree, left_and_right_lungs, segmental_bronchi_for_lobes.StartBranches, lobes, reporting);
            results = [];
            results.AirwaysBySegmentImage = segment_image_map;
            results.AirwaysBySegment = labelled_segments;
        end
        
        function results = GenerateImageFromResults(airway_results, ~, ~)
            results = airway_results.AirwaysBySegmentImage;
        end        
    end
end