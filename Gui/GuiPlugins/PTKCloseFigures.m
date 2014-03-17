classdef PTKCloseFigures < PTKGuiPlugin
    % PTKCloseFigures. Gui Plugin for closing all open figures except the PTK
    % gui
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Close figures'
        ToolTip = 'Close all open Matlab figures except the PTK gui'
        Category = 'View'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        Visibility = 'Developer'
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.CloseAllFiguresExceptPtk();
        end
    end
end