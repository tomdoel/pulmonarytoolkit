classdef MimShowPatientBrowser < MimGuiPlugin
    % MimShowPatientBrowser. Gui Plugin for displaying the study browser
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimShowPatientBrowser is a Gui Plugin for the MIM Toolkit. The gui will
    %     show or bring to the front the Patient Browser window.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
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
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 1
        Icon = 'patient_browser.png'

    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ShowPatientBrowser;
        end
    end
end