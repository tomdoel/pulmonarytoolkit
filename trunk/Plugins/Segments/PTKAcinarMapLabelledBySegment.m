classdef PTKAcinarMapLabelledBySegment < PTKPlugin
    % PTKAcinarMapLabelledBySegment. Plugin for approximating the pulmonary
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
        ButtonText = 'Acinar segment<br>map'
        ToolTip = 'Segments'
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
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            segmental_bronchi_for_lobes = dataset.GetResult('PTKAirwayGrowingLabelledBySegment');
            
            results = template.BlankCopy;
            
            segmental_index_map = zeros(template.ImageSize, 'uint8');
            airways_to_do = PTKStack(segmental_bronchi_for_lobes.StartBranches);
            while ~airways_to_do.IsEmpty
                airway = airways_to_do.Pop;
                
                if isempty(airway.Children)
                    segment_index = airway.SegmentIndex;
                    if ~isempty(segment_index)
                        local_index = PTKTreeUtilities.CentrelinePointsToLocalIndices(airway.EndPoint, template);
                        segmental_index_map(local_index) = segment_index;
                    end

                else
                    airways_to_do.Push(airway.Children);
                end
            end

            results.ChangeRawImage(segmental_index_map);
            results.ImageType = PTKImageType.Colormap;
        end
    end
end