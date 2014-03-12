classdef PTKSaveSegmentalAnalysisResults < PTKPlugin
    % PTKSaveSegmentalAnalysisResults. Plugin for performing analysis of density using bins
    % along the cranial-caudal axis
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKSaveAxialAnalysisResults divides the cranial-caudal axis into bins and
    %     performs analysis of the tissue density, air/tissue fraction and
    %     emphysema percentage in each bin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Segmental metrics'
        ToolTip = 'Performs density analysis in bins along the cranial-caudal axis'
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
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            image_info = dataset.GetImageInfo;
            results = [];
            uid = image_info.ImageUid;
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            patient_name = template.MetaHeader.PatientName.FamilyName;
            results_directory = dataset.GetOutputPathAndCreateIfNecessary;

            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe, PTKContextSet.Segment};
            
            axial_results = dataset.GetResult('PTKAxialAnalysis', contexts);
            axial_table = PTKConvertMetricsToTable(axial_results, patient_name, uid, PTKReportingDefault);
            PTKSaveTableAsCSV(results_directory, 'AxialResults_Segmental', axial_table, PTKResultsTable.ContextDim, PTKResultsTable.SliceNumberDim, PTKResultsTable.MetricDim, [], reporting);
            results.AxialResults = axial_results;
            
            density_results = dataset.GetResult('PTKDensityAnalysis', contexts);
            density_table = PTKConvertMetricsToTable(density_results, patient_name, uid, PTKReportingDefault);
            PTKSaveTableAsCSV(results_directory, 'DensityResults_Segmental', density_table, PTKResultsTable.PatientDim, PTKResultsTable.ContextDim, PTKResultsTable.MetricDim, [], reporting);
            results.DensityResults = density_results;
        end
    end
end