classdef PTKAirwayForContext < PTKPlugin
    % PTKAirwayForContext. Plugin for returning the main bronchi serving the lung regions for a given context
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKAirwayForContext returns a set of bronchi which correspond to the
    %     specified context
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Bronchus for<br>context'
        ToolTip = 'Plugin for returning the main bronchi serving the lung regions for a given context'
        Category = 'Analysis'

        Context = PTKContextSet.Any
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            bronchi = [];
            switch context
                case {PTKContext.Lungs, PTKContext.LungROI, PTKContext.OriginalImage}
                    airways = dataset.GetResult('PTKAirwayCentreline');
                    bronchi =  airways.AirwayCentrelineTree;
                case {PTKContext.LeftLung}
                    airways = dataset.GetResult('PTKAirwaysLabelledByLobe');
                    bronchi = airways.StartBranches.Left;
                case {PTKContext.RightLung}
                    airways = dataset.GetResult('PTKAirwaysLabelledByLobe');
                    bronchi = airways.StartBranches.Right;
                case {PTKContext.LeftUpperLobe}
                    airways = dataset.GetResult('PTKAirwaysLabelledByLobe');
                    bronchi = airways.StartBranches.LeftUpper;
                case {PTKContext.LeftLowerLobe}
                    airways = dataset.GetResult('PTKAirwaysLabelledByLobe');
                    bronchi = airways.StartBranches.LeftLower;
                case {PTKContext.RightUpperLobe}
                    airways = dataset.GetResult('PTKAirwaysLabelledByLobe');
                    bronchi = airways.StartBranches.RightUpper;
                case {PTKContext.RightLowerLobe}
                    airways = dataset.GetResult('PTKAirwaysLabelledByLobe');
                    bronchi = airways.StartBranches.RightLower;
                case {PTKContext.RightMiddleLobe}
                    airways = dataset.GetResult('PTKAirwaysLabelledByLobe');
                    bronchi = airways.StartBranches.RightMid;
                case {PTKContext.R_AP, PTKContext.R_P, PTKContext.R_AN, PTKContext.R_L, ...
                        PTKContext.R_M, PTKContext.R_S, PTKContext.R_MB, PTKContext.R_AB, PTKContext.R_LB, ...
                        PTKContext.R_PB, PTKContext.L_APP, PTKContext.L_APP2, PTKContext.L_AN, PTKContext.L_SL, ...
                        PTKContext.L_IL, PTKContext.L_S, PTKContext.L_AMB, PTKContext.L_LB, PTKContext.L_PB}
                    airways = dataset.GetResult('PTKSegmentsByNearestBronchus');
                    bronchi = PTKAirwayForContext.FindSegmentalBronchus(airways.AirwaysBySegment.Trachea, context);
            end
            for branch = bronchi
                branch.GenerateBranchParameters;
            end
            
            results = [];
            results.AirwayForContext = bronchi;
        end
        
        function bronchus = FindSegmentalBronchus(airways, context)
            segment_label = uint8(PTKPulmonarySegmentLabels.(char(context)));
            airways_to_do = PTKStack(airways);
            while ~airways_to_do.IsEmpty
                next_airways = airways_to_do.Pop;
                if next_airways.SegmentIndex == segment_label
                    bronchus = next_airways;
                    return;
                end
                airways_to_do.Push(next_airways.Children);
            end
            
            bronchus = [];
        end
    end
end