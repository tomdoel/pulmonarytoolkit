classdef CoreSystemUtilities
    % CoreSystemUtilities. Utility functions relating to the hardware or operating system.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)

        function uid = GenerateUid
            % Creates a random unique identifier
            
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
        
        function dimensions = GetMonitorDimensions
            % Gets the resolution of the screen
            
            if usejava('jvm')
                d = java.awt.Toolkit.getDefaultToolkit().getScreenSize();
                dimensions = [d.width, d.height];
            else
                dimensions = get(0, 'ScreenSize');
                dimensions = dimensions(3:4);
            end
        end
        
        function bytes_in_type = GetBytesInType(type_string)
            % Returns the number of bytes in the given Matlab type
            
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
                    error('CoreSystemUtilities:GetBytesInType', 'Unknown number type');
            end
        end
        
        function computer_endian = GetComputerEndian
            % Returns an enumeration for the endian of this computer
            
            [~, ~, computer_endian_str] = computer;
            
            switch computer_endian_str
                case 'B'
                    computer_endian = CoreEndian.BigEndian;
                case 'L'
                    computer_endian = CoreEndian.LittleEndian;
                otherwise
                    error('CoreSystemUtilities:GetComputerEndian', 'Unknown endian');
            end
        end

        function DeleteIfValidObject(object_handle)
            % Deletes an object
            
            if ~isempty(object_handle)
                if isvalid(object_handle)
                    delete(object_handle);
                end
            end
        end
        
        function DeleteIfGraphicsHandle(handle)
            % Removes a graphics handle
            
            if ishandle(handle)
                delete(handle);
            end
        end
        
        function colormap = BackwardsCompatibilityColormap
            % Returns a colormap which replicates the default colormap from
            % Matlab versions pre-hg2
            
            old_colormap = [0 0 1; 0 0.5 0; 1 0 0; 0 0.75 0.75; 0.75 0 0.75; 0.75 0.75 0; 0.25 0.25 0.25];
            colormap = repmat(old_colormap, [9, 1]);
            colormap = [colormap; [0 0 1]];
        end
        
        function [major_version, minor_version] = GetMatlabVersion
            % Returns the major and minor version numbers of Matlab
            
            [matlab_version, ~] = version;
            version_matrix = sscanf(matlab_version, '%d.%d.%d.%d');
            major_version = version_matrix(1);
            minor_version = version_matrix(2);
        end
        
        function toolbox_installed = IsImageProcessingToolboxInstalled
            % Returns true if the Matlab image processing toolbox is
            % installed
            
            matlab_version = ver;
            toolbox_installed = any(strcmp('Image Processing Toolbox', {matlab_version.Name}));
        end

        function toolbox_licensed = IsImageProcessingToolboxLicensed
            % Returns true if the Matlab image processing toolbox has a valid licence
            
            [error_code, error_message] = license('checkout', 'image_toolbox');
            toolbox_licensed = error_code == 1;
        end
        
    end
end

