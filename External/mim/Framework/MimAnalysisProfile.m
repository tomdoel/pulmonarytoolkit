classdef MimAnalysisProfile < handle
    % MimAnalysisProfile. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     Used to cache plugin results in memory.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        
    
    properties (Access = private)
        ProfileMap
    end
    
    methods
        function obj = MimAnalysisProfile()
            obj.ProfileMap = containers.Map();
        end
        
        function is_active = IsActive(obj, name, default)
            if ~obj.ProfileMap.isKey(name)
                obj.ProfileMap(name) = default;
            end
            is_active = obj.ProfileMap(name);
        end
        
        function SetProfileActive(obj, name, is_active)
            obj.ProfileMap(name) = is_active;
        end
    end
end
