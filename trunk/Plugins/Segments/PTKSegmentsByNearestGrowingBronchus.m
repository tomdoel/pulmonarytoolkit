classdef PTKSegmentsByNearestGrowingBronchus < PTKPlugin
    % PTKSegmentsByNearestGrowingBronchus. Plugin for approximating the pulmonary
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
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Segments by<br>nearest bronchus'
        ToolTip = 'Finds the segments by dividing the volume according to the nearest bronchus from the airway growing tree'
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
        Visibility = 'Developer'
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            
            acinar_map = dataset.GetResult('PTKAcinarMapLabelledBySegment');
            lobes = dataset.GetResult('PTKLobesFromFissurePlane');
            results = lobes.BlankCopy;
            results.ChangeRawImage(zeros(lobes.ImageSize, 'uint8'));
            
            lobe_labels = [1, 2, 4, 5, 6];
            segmental_labels = {[1,2,3], [4,5], [6,7,8,9,10], [11,13,14,15], [18,18,19,20]};
            
            for lobe_index = 1 : 5
                lobe_label = lobe_labels(lobe_index);
                lobe_mask = lobes.BlankCopy;
                lobe_mask.ChangeRawImage(lobes.RawImage == lobe_label);
                segments_map = PTKSegmentsByNearestGrowingBronchus.ComputeForLobe(lobe_mask, acinar_map, segmental_labels{lobe_index}, reporting);
                results.ChangeSubImageWithMask(segments_map, lobe_mask);
            end
        end
        
        function segment_map = ComputeForLobe(lobe_mask, acinar_map, segmental_labels, reporting)
            template = lobe_mask.BlankCopy;
            nn_mask = false(lobe_mask.ImageSize);
            for segment_index = segmental_labels
                nn_mask(acinar_map.RawImage == segment_index) = true;
            end
            [~, nn_index] = bwdist(nn_mask);
            segment_map = lobe_mask.BlankCopy;
            segment_map.ChangeRawImage(acinar_map.RawImage(nn_index));
            segment_map.ResizeToMatch(template);
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end        
    end
end