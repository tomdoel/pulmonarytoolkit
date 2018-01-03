classdef PTKAnalyseAndSaveCT < MimGuiPlugin
    % PTKAnalyseAndSaveCT. GUI Plugin for performing analysis of regions on CT data
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Run analysis'
        SelectedText = 'Run analysis'
        ToolTip = 'Performs density analysis over specified regions'
        Category = 'CT regional'
        Visibility = 'Dataset'
        Mode = 'Analysis'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'icon_lobes.png'
        Location = 1
        
        ShowProgressDialog = true
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app, reporting)
            image_info = gui_app.GetImageInfo();
            uid = image_info.ImageUid;
            patient_name = gui_app.GetPatientName();

            if gui_app.AnalysisProfile.IsActive('Manual', true)
                contexts = gui_app.GetAllContextsForManualSegmentations();
            else
                contexts = {};
            end
            
            if gui_app.AnalysisProfile.IsActive('Lung', true)
                contexts{end + 1} = PTKContextSet.SingleLung;
                contexts{end + 1} = PTKContextSet.Lungs;
            end
            
            if gui_app.AnalysisProfile.IsActive('Lobes', true)
                contexts{end + 1} = PTKContextSet.Lobe;
            end
            
            density_metrics = gui_app.RunPluginCallback('PTKCTDensityAnalysis', contexts);
            emphysema_results = gui_app.RunPluginCallback('PTKEmphysemaAnalysis', contexts);
            results = PTKMetrics.MergeResults(density_metrics, emphysema_results);            
            
            if gui_app.AnalysisProfile.IsActive('Airways', true)
                airway_metrics = gui_app.RunPluginCallback('PTKAirwayAnalysis', contexts);
                results = PTKMetrics.MergeResults(results, airway_metrics);            
            end
            
            table = PTKConvertMetricsToTable(results, patient_name, uid, reporting);
            
            gui_app.SaveTableAsCSV('PTKCTAnalysis', 'CT analysis', 'CTResults', 'Analysis of CT datasets over regions', table, MimResultsTable.PatientDim, MimResultsTable.ContextDim, MimResultsTable.MetricDim, []);
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded() && gui_app.IsCT();
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = false;
        end

    end
end
