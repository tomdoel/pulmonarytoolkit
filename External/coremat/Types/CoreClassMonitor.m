classdef (Sealed) CoreClassMonitor < handle
    % CoreClassMonitor. Monitors creation and destruction of classes
    %
    %     This class repesents a singleton which reference counts objects 
    %     (of base type CoreBaseClass). It is used in testing to ensure that
    %     objects have been destroyed properly (i.e. that references to the
    %     objects have been correctly removed).
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        CountMap
    end
        
    methods (Static)
        function class_monitor = GetClassMonitor
            persistent ClassMonitor
            if isempty(ClassMonitor) || ~isvalid(ClassMonitor)
                ClassMonitor = CoreClassMonitor;
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
        function obj = CoreClassMonitor
            obj.CountMap = containers.Map;
        end
    end
    
end
