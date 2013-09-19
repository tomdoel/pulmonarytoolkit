classdef PTKFissurePlane < PTKPlugin
    % PTKFissurePlane. Plugin to obtain an approximation of the fissures
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     This is an intermediate stage towards lobar segmentation.
    %
    %     PTKFissureApproximation uses the approximate lobar segmentation
    %     generated using PTKLobesByVesselnessDensityUsingWatershed. The fissures
    %     are the watershed boundaries within the lung.
    %
    %     For more information, see
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fissure Plane'
        ToolTip = ''
        Category = 'Fissures'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            results = application.GetResult('PTKFissurePlaneOblique');
            horiztonal_results = application.GetResult('PTKFissurePlaneHorizontal');
            horiztonal_results.ResizeToMatch(results);
            oblique_results_raw = results.RawImage;
            oblique_results_raw(horiztonal_results.RawImage == 2) = 2;
            results.ChangeRawImage(oblique_results_raw);
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end
end