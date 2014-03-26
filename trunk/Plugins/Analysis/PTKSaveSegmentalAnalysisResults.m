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
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            image_info = dataset.GetImageInfo;
            results = [];
            uid = image_info.ImageUid;
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            patient_name = template.MetaHeader.PatientName.FamilyName;

            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe, PTKContextSet.Segment};
            
            axial_results = dataset.GetResult('PTKAxialAnalysis', contexts);
            axial_table = PTKConvertMetricsToTable(axial_results, patient_name, uid, PTKReportingDefault);
            dataset.SaveTableAsCSV('PTKSaveSegmentalAnalysisResults', 'Segmental axial metrics', 'AxialResults_Segmental', 'Segmental analysis in bins along the cranial-caudal axis', axial_table, PTKResultsTable.ContextDim, PTKResultsTable.SliceNumberDim, PTKResultsTable.MetricDim, []);
            results.AxialResults = axial_results;

            coronal_results = dataset.GetResult('PTKCoronalAnalysis', contexts);
            coronal_table = PTKConvertMetricsToTable(coronal_results, patient_name, uid, PTKReportingDefault);
            dataset.SaveTableAsCSV('PTKSaveSegmentalAnalysisResults', 'Segmental coronal metrics', 'CoronalResults_Segmental', 'Segmental analysis in bins along the anterior-posterior axis', coronal_table, PTKResultsTable.ContextDim, PTKResultsTable.SliceNumberDim, PTKResultsTable.MetricDim, []);
            results.CoronalResults = coronal_results;

            density_results = dataset.GetResult('PTKDensityAnalysis', contexts);
            density_table = PTKConvertMetricsToTable(density_results, patient_name, uid, PTKReportingDefault);
            dataset.SaveTableAsCSV('PTKSaveSegmentalAnalysisResults', 'Segmental metrics', 'DensityResults_Segmental', 'Density analysis for the pulmonary segments', density_table, PTKResultsTable.PatientDim, PTKResultsTable.ContextDim, PTKResultsTable.MetricDim, []);
            results.DensityResults = density_results;
        end
    end
end