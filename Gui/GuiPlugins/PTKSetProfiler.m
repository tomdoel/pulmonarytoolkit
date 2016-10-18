classdef PTKSetProfiler < PTKGuiPlugin
    % PTKSetProfiler. Gui Plugin for enabling or disabling developer mode
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Profiler'
        SelectedText = 'Finish profiling'
        ToolTip = 'Starts or stops the Matlab profiler'
        Category = 'Developer tools'
        Visibility = 'Developer'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        Icon = 'timer.png'        
        Location = 110
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            if ~isdeployed
                profile_status = profile('status');

                if strcmp(profile_status.ProfilerStatus, 'on');
                    profile viewer
                else
                    profile on
                end
            end
        end

        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.DeveloperMode;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            if isdeployed
                is_selected = false;
            else
                profile_status = profile('status');
                is_selected = strcmp(profile_status.ProfilerStatus, 'on');
            end
        end
    end
end