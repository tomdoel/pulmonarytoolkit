classdef (Abstract) MimWSModel  < handle
    methods (Abstract)
        value = getValue(obj)
    end
end