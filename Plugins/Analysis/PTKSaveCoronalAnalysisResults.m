classdef PTKSaveCoronalAnalysisResults < PTKPlugin
    % PTKSaveCoronalAnalysisResults. Plugin for performing analysis of density using bins
    % along the anterior-posterior axis
    %
    % This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    % the gui, or through the interfaces provided by the Pulmonary Toolkit.
    % See PTKPlugin.m for more information on how to run plugins.
    %
    % Plugins should not be run directly from your code.
    %
    %     PTKSaveCoronalAnalysisResults divides the cranial-caudal axis into bins and
    %     performs analysis of the tissue density, air/tissue fraction and
    %     emphysema percentage in each bin.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Coronal analysis'
        ToolTip = 'Performs density analysis in bins along the anterior-posterior axis'
        Category = 'Slice-by-slice'
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
        Location = 31
        Icon = 'cor_slices.png'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            
            % Generate the results over the lungs and lobes
            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe};
            results = dataset.GetResult('PTKCoronalAnalysis', contexts);            
            
            % Convert the results into a MimResultsTable
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            patient_name = dataset.GetPatientName;
            table = PTKConvertMetricsToTable(results, patient_name, uid, reporting);

            % Save the results table as a series of CSV files
            dataset.SaveTableAsCSV('PTKSaveCoronalAnalysisResults', 'Coronal analysis', 'CoronalResults', 'Density analysis in bins along the anterior-posterior axis', table, MimResultsTable.ContextDim, MimResultsTable.SliceNumberDim, MimResultsTable.MetricDim, []);
            
            % Generate graphs of the results
            y_label = 'Distance along coronal axis (%)';
            
            context_list_both_lungs = [PTKContext.Lungs];
            PTKSaveCoronalAnalysisResults.DrawGraphAndSave(dataset, table, y_label, context_list_both_lungs, '_CombinedLungs', reporting);

            context_list_single_lungs = [PTKContext.LeftLung, PTKContext.RightLung];
            PTKSaveCoronalAnalysisResults.DrawGraphAndSave(dataset, table, y_label, context_list_single_lungs, '_Lungs', reporting);
            
            context_list_lobes = [PTKContext.LeftLowerLobe, PTKContext.LeftUpperLobe, PTKContext.RightLowerLobe, PTKContext.RightMiddleLobe, PTKContext.RightUpperLobe];                        
            PTKSaveCoronalAnalysisResults.DrawGraphAndSave(dataset, table, y_label, context_list_lobes, '_Lobes', reporting);
            
            results = [];
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded() && gui_app.IsCT();
        end
    end
    
    methods (Static, Access = private)
        function DrawGraphAndSave(dataset, table, y_label, context_list, file_suffix, reporting)
            figure_handle = PTKGraphMetricVsDistance(table, 'MeanDensityGml', 'StdDensityGml', context_list, [], y_label, reporting);
            dataset.SaveFigure(figure_handle, 'PTKSaveCoronalAnalysisResults', 'Coronal analysis', ['DensityVsCoronalDistance' file_suffix], 'Graph of density vs distance along the anterior-posterior axis');
            close(figure_handle);
            
            figure_handle = PTKGraphMetricVsDistance(table, 'EmphysemaPercentage', [], context_list, [], y_label, reporting);            
            dataset.SaveFigure(figure_handle, 'PTKSaveCoronalAnalysisResults', 'Coronal analysis', ['EmphysemaVsCoronalDistance' file_suffix], 'Graph of emphysema vs distance along the anterior-posterior axis');
            close(figure_handle);
        end
    end        
end