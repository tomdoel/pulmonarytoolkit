classdef MatNatBase < handle
    % The base types for MatNat classes
    %
    % .. Licence
    %    -------
    %    Part of MatNat. https://github.com/tomdoel/matnat
    %    Author: Tom Doel, 2015.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    methods (Static, Access = protected)
        function value = getOptionalProperty(baseObject, propertyName)
            % Returns a value if that value exists in the provided
            % structure, otherwise return an empty value
            
            if isfield(baseObject, propertyName)
                value = baseObject.(propertyName);
            else
                value = [];
            end
        end
    end
    
end

