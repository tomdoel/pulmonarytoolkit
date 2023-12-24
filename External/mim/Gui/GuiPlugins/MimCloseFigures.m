classdef MimCloseFigures < MimGuiPlugin
    % MimCloseFigures. Gui Plugin for closing all open figures except the
    % main gui
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Close Figures'
        SelectedText = 'Close Figures'
        ToolTip = 'Close all open Matlab figures except the MIM gui'
        Category = 'Developer tools'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
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