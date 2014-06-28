classdef PTKSaveAirwayMesh < PTKPlugin
    % PTKSaveAirwayMesh. Plugin for saving an STL file containing the surface
    %     mesh of the airways, pruned to the segmental level
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
        ButtonText = 'Save airway<br>mesh'
        ToolTip = 'Segments the airway lumen down to the segmental bronchi, and then creates and saves an STL mesh of the lumen surface'
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
            airways_by_segment_pruned = dataset.GetResult('PTKAirwaysPrunedBySegment');
            results = airways_by_segment_pruned.PrunedSegmentsByLobeImage;
            results.ChangeRawImage(results.RawImage > 0);
            
            smoothing_size = 1;
            filename = 'PrunedAirwaysSurfaceMesh.stl';
            results_upsampled = results.Copy;
            results_upsampled.AddBorder(6);
            results_upsampled.DownsampleImage(0.25);

            % Specifies the coordinate system to use when saving out files
            coordinate_system = PTKCoordinateSystem.DicomUntranslated;
            
            template_image = results;
            
            small_structures = true;
            dataset.SaveSurfaceMesh('PTKSaveAirwayMesh', 'Airway mesh', filename, 'Surface mesh of the segmented airways down to the level of the pulmonary segments' , results, smoothing_size, small_structures, coordinate_system, template_image);
        end
        
        function results = GenerateImageFromResults(results, image_templates, reporting)
        end        
    end
end