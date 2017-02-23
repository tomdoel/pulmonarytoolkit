classdef TestMimWebsocketParser < CoreTest
    % TestMimWebsocketParser. Tests for the MimWebSocketParser class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestMimWebsocketParser
            metadata_expected = struct('az', 'by');
            textvalue_expected = 'Text-Data';
            header_expected = MimWebSocketParser.EncodeAsStruct('myModelName', '12345', '23456', [], MimWebSocketParser.MimPayloadData, []);
            jsonString = MimWebSocketParser.EncodeAsString('myModelName', '12345', '23456', metadata_expected, MimWebSocketParser.MimPayloadData, textvalue_expected);
            [header_out, metadata_out, value_out] = MimWebSocketParser.ParseString(jsonString);
            obj.Assert(isequal(header_expected, header_out), 'Header structs are the same');
            obj.Assert(isequal(metadata_expected, metadata_out), 'Metadata structs are the same');
            obj.Assert(isequal(textvalue_expected, value_out), 'Header structs are the same');
            
            value_expected = [1 2 3 4 5; 6 7 8 9 10];
            blob = MimWebSocketParser.EncodeAsBlob('myModelName', '12345', '23456', metadata_expected, MimWebSocketParser.MimPayloadData, value_expected);
            header_expected = MimWebSocketParser.EncodeAsStruct('myModelName', '12345', '23456', [], MimWebSocketParser.MimPayloadData, []);
            [header_out, metadata_out, value_out] = MimWebSocketParser.ParseBlob(blob);
            obj.Assert(isequal(header_expected, header_out), 'Header structs are the same');
            obj.Assert(isequal(metadata_expected, metadata_out), 'Metadata structs are the same');
            obj.Assert(isequal(value_expected, value_out), 'Header structs are the same');
        end
    end
end