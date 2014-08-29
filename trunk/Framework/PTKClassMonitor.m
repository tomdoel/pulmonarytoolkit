classdef (Sealed) PTKClassMonitor < handle
    % PTKClassMonitor. For testing purposes, monitors creation and destruction of classes
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        CountMap
    end
        
    methods (Static)
        function class_monitor = GetClassMonitor
            persistent ClassMonitor
            if isempty(ClassMonitor) || ~isvalid(ClassMonitor)
                ClassMonitor = PTKClassMonitor;
            end
            class_monitor = ClassMonitor;
        end
    end
    
    methods
        function Reset(obj)
            obj.CountMap = containers.Map;
        end
        
        function ObjectCreated(obj, class_name)
            if obj.CountMap.isKey(class_name)
                obj.CountMap(class_name) = obj.CountMap(class_name) + 1;
            else
                obj.CountMap(class_name) = 1;
            end
        end
        
        function ObjectDeleted(obj, class_name)
            if obj.CountMap.isKey(class_name)
                obj.CountMap(class_name) = obj.CountMap(class_name) - 1;
            end
        end
        
        function Status(obj)
            keys = obj.CountMap.keys;
            all_ok = true;
            for index = 1 : obj.CountMap.Count
                next_key = keys{index};
                next_value = obj.CountMap(next_key);
                if next_value ~= 0
                    disp(['*** Class ', next_key, ' has ', int2str(next_value), ' instances left']);
                    all_ok = false;
                end
            end
            
            if all_ok
                disp(['OK:', int2str(obj.CountMap.Count) ' classes checked']);
            end
        end
    end
    
    methods (Access = private)
        function obj = PTKClassMonitor
            obj.CountMap = containers.Map;
        end
    end
    
end
