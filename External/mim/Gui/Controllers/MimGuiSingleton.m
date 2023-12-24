classdef (Sealed) MimGuiSingleton < handle
    % MimGuiSingleton. The singleton used by all instances of MimGui
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the TD MIM Toolkit.
    %
    %     MimGuiSingleton ensures there is only a single instance for writing
    %     settings to disk, allowing multiple GUI windows to exist simultaneously.
    %
    %     MimGuiSingleton is a singleton. It cannot be created using the
    %     constructor; instead call MimGuiSingleton.GetGuiSingleton;
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        Settings
    end
        
    methods (Static)
        function gui_singleton = GetGuiSingleton(app_def, reporting)
            persistent GuiSingleton
            if isempty(GuiSingleton) || ~isvalid(GuiSingleton)
                GuiSingleton = MimGuiSingleton(app_def, reporting);
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
        function obj = MimGuiSingleton(app_def, reporting)
            obj.Settings = PTKSettings.LoadSettings(app_def, reporting);
        end
    end
    
end
