classdef PTKSystemUtilities
    % PTKSystemUtilities. Utility functions relating to the hardware or operating system.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)

        % Creates a random unique identifier
        function uid = GenerateUid
            % On unix systems, if java is not running we can use the system
            % command
            if isunix && ~usejava('jvm')
                [status, uid] = system('uuidgen');
                if status ~= 0
                    error('Failure running uuidgen');
                end
            else
                uid = char(java.util.UUID.randomUUID);
            end
        end
        
        % Gets the resolution of the screen
        function dimensions = GetMonitorDimensions
            if usejava('jvm')
                d = java.awt.Toolkit.getDefaultToolkit().getScreenSize();
                dimensions = [d.width, d.height];
            else
                dimensions = get(0, 'ScreenSize');
                dimensions = dimensions(3:4);
            end
        end
        
        function bytes_in_type = GetBytesInType(type_string, reporting)
            switch type_string
                case {'int8', 'uint8'}
                    bytes_in_type = 1;
                case {'uint16', 'int16'}
                    bytes_in_type = 2;
                case {'uint32', 'int32'}
                    bytes_in_type = 4;
                case {'uint64', 'int64'}
                    bytes_in_type = 8;
                otherwise
                    reporting.Error('PTKSystemUtilities:GetBytesInType', 'Unknown number type');
            end
        end
        
        function computer_endian = GetComputerEndian(reporting)
            [~, ~, computer_endian_str] = computer;
            
            switch computer_endian_str
                case 'B'
                    computer_endian = PTKEndian.BigEndian;
                case 'L'
                    computer_endian = PTKEndian.LittleEndian;
                otherwise
                    reporting.Error('PTKSystemUtilities:GetComputerEndian', 'Unknown endian');
            end
        end

    end
end

