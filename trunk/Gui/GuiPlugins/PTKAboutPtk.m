classdef PTKAboutPtk < PTKGuiPlugin
    % PTKAboutPtk. Gui Plugin for displaying an "about box" dialog
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKAboutPtk is a Gui Plugin for the TD Pulmonary Toolkit. The gui will
    %     create a button to run this plugin. Running this plugin will cause a
    %     splash screen dialog to be displayed.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'About'
        ToolTip = 'Shows a dialog with more information about this program'
        Category = 'File'
        Visibility = 'Always'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(~)
            PTKSplashScreen;
        end
    end
end