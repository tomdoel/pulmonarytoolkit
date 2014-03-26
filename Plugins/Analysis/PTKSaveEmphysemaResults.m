classdef PTKSaveEmphysemaResults < PTKPlugin
    % PTKSaveEmphysemaResults. 
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
        ButtonText = 'Emphysema metrics'
        ToolTip = 'Calculates emphysema percentage and percentile density for the lungs and lobes'
        Category = 'Analysis'
        Mode = 'Analysis'

        Context = PTKContextSet.LungROI
        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            patient_name = template.MetaHeader.PatientName.FamilyName;

            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe};
            results = dataset.GetResult('PTKEmphysemaAnalysis', contexts);
            
            table = PTKConvertMetricsToTable(results, patient_name, uid, PTKReportingDefault);
            
            dataset.SaveTableAsCSV('PTKSaveEmphysemaResults', 'Emphysema metrics', 'EmphysemaResults', 'CT density-based emphysema analysis', table, PTKResultsTable.PatientDim, PTKResultsTable.ContextDim, PTKResultsTable.MetricDim, []);
        end
    end
end