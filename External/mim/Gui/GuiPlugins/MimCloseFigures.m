classdef MimCloseFigures < MimGuiPlugin
    % MimCloseFigures. Gui Plugin for closing all open figures except the
    % main gui
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Close Figures'
        SelectedText = 'Close Figures'
        ToolTip = 'Close all open Matlab figures except the PTK gui'
        Category = 'Developer tools'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        Visibility = 'Developer'
        Location = 100
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.CloseAllFiguresExceptMim();
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.DeveloperMode;
        end
        
    end
end