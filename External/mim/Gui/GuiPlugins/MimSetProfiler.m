classdef MimSetProfiler < MimGuiPlugin
    % MimSetProfiler. Gui Plugin for enabling or disabling developer mode
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
        ButtonText = 'Start profiler'
        SelectedText = 'Finish profiling'
        ToolTip = 'Starts or stops the Matlab profiler'
        Category = 'Developer tools'
        Visibility = 'Always'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'timer.png'        
        Location = 110
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            if ~isdeployed
                profile_status = profile('status');

                if strcmp(profile_status.ProfilerStatus, 'on');
                    profile viewer
                else
                    profile on
                end
            end
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.DeveloperMode;
        end
        
        function is_selected = IsSelected(gui_app)
            if isdeployed
                is_selected = false;
            else
                profile_status = profile('status');
                is_selected = strcmp(profile_status.ProfilerStatus, 'on');
            end
        end
    end
end