classdef PTKSaveLobeMesh < PTKPlugin
    % PTKSaveLobeMesh. Plugin for creating an STL surface mesh file
    %     for each lobe
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
        ButtonText = 'Save lobe <br>mesh'
        ToolTip = 'Saves STL meshes for each lobe in the Output folder'
        Category = 'Lobes'

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
            reporting.ShowProgress('Creating mesh for lobes');

            lobes = dataset.GetResult('PTKLobesFromFissurePlane');
            
            lobe_names = {'RU', 'RM', 'RL', 'LU', 'LL'};
            lobe_index_colours = [1, 2, 4, 5, 6];

            coordinate_system = PTKCoordinateSystem.DicomUntranslated;
            template_image = lobes;

            for lobe_index = 1 : 5
                reporting.UpdateProgressStage((lobe_index-1), 5);
                
                current_lobe = lobes.Copy;
                current_lobe.ChangeRawImage(lobes.RawImage == lobe_index_colours(lobe_index));
                current_lobe = PTKFillHolesInImage(current_lobe);
                
                smoothing_size = 3;
                filepath = dataset.GetOutputPathAndCreateIfNecessary;
                filename = ['LobeSurfaceMesh_' lobe_names{lobe_index} '.stl'];
                current_lobe.AddBorder(6);
                reporting.PushProgress;
                PTKCreateSurfaceMesh(filepath, filename, current_lobe, smoothing_size, false, coordinate_system, template_image, reporting);
                reporting.PopProgress;
            end
            results = lobes;
            reporting.UpdateProgressValue(100);
            reporting.CompleteProgress;
            
        end
        
        function results = GenerateImageFromResults(results, image_templates, reporting)
        end        
    end
end