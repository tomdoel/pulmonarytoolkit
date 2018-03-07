classdef (Abstract) MimModelCollection  < MimModel
	
    methods
        function addItem(obj, itemId)
            [currentCollection, ~] = obj.getOrRun();
            if ~ismember(itemId, currentCollection)
                currentCollection{end + 1} = itemId;
                obj.setValue(currentCollection);
            end
        end
        
        function removeItem(obj, itemId)
            [currentCollection, ~] = obj.getOrRun();
            if ismember(itemId, currentCollection)
                currentCollection = setdiff(currentCollection, itemId);
                obj.setValue(currentCollection);
            end
        end
    end
end
