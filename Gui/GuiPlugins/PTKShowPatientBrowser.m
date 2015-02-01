classdef PTKShowPatientBrowser < PTKGuiPlugin
    % PTKShowPatientBrowser. Gui Plugin for displaying the study browser
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKShowStudyBrowser is a Gui Plugin for the TD Pulmonary Toolkit. The gui will
    %     show or bring to the front the Patient Browser window.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Patient Browser'
        SelectedText = 'Patient Browser'
        ToolTip = 'Shows the Patient Browser'
        Category = 'Dataset'
        Visibility = 'Always'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        Location = 1
        Icon = 'patient_browser.png'

    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ShowPatientBrowser;
        end
    end
end