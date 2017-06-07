classdef (Abstract) MimStorageClass  < handle
	
    methods (Abstract)
        [metaData, dataStream] = getStream(obj)
    end
end