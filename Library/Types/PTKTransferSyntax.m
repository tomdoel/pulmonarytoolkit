classdef PTKTransferSyntax
    % PTKTransferSyntax.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        Endian
        VRType
        CharacterEncoding
        Compression
    end
    
    methods
        function obj = PTKTransferSyntax(endian, vr_type, char_encoding, compression)
            obj.Endian = endian;
            obj.VRType = vr_type;
            obj.CharacterEncoding = char_encoding;
            obj.Compression = compression;
        end
    end
end