classdef TDFissureness < TDPlugin
    % TDFissureness. Plugin to detect fissures 
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     This is an intermediate stage towards lobar segmentation.
    %
    %     TDFissureness computes the fissureness by combining two components
    %     generated from the two plugins TDFissurenessHessianFactor and
    %     TDFissurenessVesselsFactor.
    %
    %     For more information, see 
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Fissureness'
        ToolTip = 'Fissureness filter for detecting plane-like points with suppression of points close to vessels'
        Category = 'Fissures'
        
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
            fissureness_from_hessian = single(dataset.GetResult('TDFissurenessHessianFactor').RawImage)/100;
            fissureness_from_vessels = single(dataset.GetResult('TDFissurenessVesselsFactor').RawImage)/100;
            results = dataset.GetTemplateImage(TDContext.LungROI);
            results.ChangeRawImage(100*fissureness_from_vessels.*fissureness_from_hessian);
            results.ImageType = TDImageType.Scaled;
        end        
        
    end
end
