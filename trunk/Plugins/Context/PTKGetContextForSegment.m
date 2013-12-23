classdef PTKGetContextForSegment < PTKPlugin
    % PTKGetContextForSegment. Plugin for finding the region of interest for a segment.
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
        ButtonText = 'Segment<BR>ROI'
        ToolTip = 'Fetches the ROI for a segment context'
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        Context = PTKContextSet.Segment
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            segment_mask = dataset.GetResult('PTKSegmentsByNearestGrowingBronchus', PTKContext.LungROI);
            results = PTKGetSegmentROI(segment_mask, context, reporting);
        end
    end
end