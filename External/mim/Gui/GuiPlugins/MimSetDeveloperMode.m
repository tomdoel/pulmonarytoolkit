classdef MimSetDeveloperMode < MimGuiPlugin
    % MimSetDeveloperMode. Gui Plugin for enabling or disabling developer mode
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Developer tools'
        SelectedText = 'Developer tools off'
        ToolTip = 'Enables or disabled developer mode'
        Category = 'Developer'
        Visibility = 'Always'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Icon = 'developer_tools.png'
        Location = 30
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            % Toggles developer mode
            gui_app.DeveloperMode = ~gui_app.DeveloperMode;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = true;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.DeveloperMode;
        end
    end
end