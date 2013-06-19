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

    end
end

