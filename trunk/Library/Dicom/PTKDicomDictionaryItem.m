classdef PTKDicomDictionaryItem
    % PTKDicomDictionaryItem
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
        Tag
        TagIndex
        TagString
        VRType
        Name
    end
    
    methods
        function obj = PTKDicomDictionaryItem(tag_string, vr_type, name)
            obj.TagString = tag_string;
            obj.Tag = [hex2dec(tag_string(1:4)), hex2dec(tag_string(6:9))];
            obj.TagIndex = uint32(hex2dec([tag_string(1:4) tag_string(6:9)]));
            obj.VRType = vr_type;
            obj.Name = name;
        end
    end
end