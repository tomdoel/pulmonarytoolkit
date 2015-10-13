classdef DMDicomDictionaryItem
    % DMDicomDictionaryItem Used in cretating a DMDicomDictionary
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %    

    properties
        Tag
        TagIndex
        TagString
        VRType
        Name
    end
    
    methods
        function obj = DMDicomDictionaryItem(tag_string, vr_type, name)
            obj.TagString = tag_string;
            obj.Tag = [hex2dec(tag_string(1:4)), hex2dec(tag_string(6:9))];
            obj.TagIndex = uint32(hex2dec([tag_string(1:4) tag_string(6:9)]));
            obj.VRType = vr_type;
            obj.Name = name;
        end
    end
end