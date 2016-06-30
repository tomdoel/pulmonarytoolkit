classdef (Sealed) PTKGuiSingleton < handle
    % PTKGuiSingleton. The singleton used by all instances of PTKGui
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %     PTKGuiSingleton ensures there is only a single instance for writing
    %     settings to disk, allowing multiple GUI windows to exist simultaneously.
    %
    %     PTKGuiSingleton is a singleton. It cannot be created using the
    %     constructor; instead call PTKGuiSingleton.GetGuiSingleton;
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Settings
    end
        
    methods (Static)
        function gui_singleton = GetGuiSingleton(app_def, reporting)
            persistent GuiSingleton
            if isempty(GuiSingleton) || ~isvalid(GuiSingleton)
                GuiSingleton = PTKGuiSingleton(app_def, reporting);
            end
            gui_singleton = GuiSingleton;
        end
    end
    
    methods
        function settings = GetSettings(obj)
            settings = obj.Settings;
        end
    end
    
    methods (Access = private)
        function obj = PTKGuiSingleton(app_def, reporting)
            obj.Settings = PTKSettings.LoadSettings(app_def, reporting);
        end
    end
    
end
