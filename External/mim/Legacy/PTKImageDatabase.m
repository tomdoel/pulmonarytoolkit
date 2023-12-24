classdef PTKImageDatabase < handle
    % Legacy support class for backwards compatibility. Replaced by MimImageDatabase
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    methods (Static)
        function obj = loadobj(property_struct)
            % This method is called when the object is loaded from disk.
            % Due to the class change, we expect property_struct to be a struct
            
            obj = MimImageDatabase.loadobj(property_struct);
        end
    end    
end