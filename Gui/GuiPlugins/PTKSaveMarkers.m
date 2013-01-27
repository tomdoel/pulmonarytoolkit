classdef PTKSaveMarkers < PTKGuiPlugin
    % PTKSaveMarkers. Gui Plugin for saving the current set of markers.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKSaveMarkers is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will save the current set of markers which are in
    %     the visualisation window. The markers will be saved as a labeled image
    %     in the dataset cache folder.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Save Markers'
        ToolTip = 'Saves the current marker into the cache file MarkerPoints for this dataset'
        Category = 'File'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.SaveMarkers;
        end
    end
end