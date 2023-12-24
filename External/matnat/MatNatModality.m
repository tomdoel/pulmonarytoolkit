classdef MatNatModality
    % Enumeration representing a modality for imaging data
    %
    % .. Licence
    %    -------
    %    Part of MatNat. https://github.com/tomdoel/matnat
    %    Author: Tom Doel, 2015.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    properties
        Name
        XnatType
    end
    
    methods
        function obj = MatNatModality(name, xnatType)
            obj.Name = name;
            obj.XnatType = xnatType;
        end
    end

    enumeration
        MR ('MR', 'xnat:mrScanData')
    end
    
    properties
    end
    
    methods (Static)
        function modality = getModalityFromXnatString(xnatType)
            % Get the modality type from the Xnat type string
            
            allEnums = enumeration('MatNatModality');
            for enum = allEnums
                if strcmp(xnatType, enum.XnatType)
                    modality = enum;
                    return;
                end
            end
            modality = [];
        end
    end
end

