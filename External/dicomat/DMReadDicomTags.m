function header = DMReadDicomTags(fileName, dictionary)
    % DMReadDicomTags Reads in metainformation from a Dicom file.
    %
    % Usage:
    %     header = DMReadDicomTags(fileName, dictionary)
    %
    %     fileName: path and filename of the Dicom file to read
    %
    %     dictionary - an object of class DMDicomDictionary containing the tags
    %         to fetch.
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %        

    tag_map = dictionary.TagMap;
    tag_list = dictionary.TagList;
    
    [is_dicom, header] = ReadDicomFile(fileName, tag_list, tag_map);
end

function [is_dicom, header] = ReadDicomFile(fileName, tag_list, tag_map)
    
    % Read the data into a local byte array
    file_id = fopen(fileName, 'r');
    file_data = fread(file_id, 'uint8=>uint8');
    file_data = file_data';
    fclose(file_id);
    
    if numel(file_data) < 132
        is_dicom = false;
        header = [];
        return;
    end
    
    % Check this is a Dicom file
    dicom_chars = char(file_data(129:132));
    is_dicom = strcmp(dicom_chars, 'DICM');
    if ~is_dicom
        header = [];
        return;
    end
    
    data_pointer = uint32(133);
    computer_endian = CoreSystemUtilities.GetComputerEndian;
    
    % All tags up to group (0002) are in explicit VR little endian.
    % After that we change to implicit VR and big endian if necessary
    is_explicit_vr = true;
    is_little_endian = true;
    file_endian_matches_computer_endian = (computer_endian == CoreEndian.LittleEndian);
    
    [header, is_little_endian, ~] = ParseFileData(file_data, data_pointer, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian, false);
    if isfield(header, 'PixelData')
        header.PixelData = DMReconstructDicomImageFromHeader(header, is_little_endian);
    end
end

function [header, is_little_endian, data_pointer] = ParseFileData(file_data, data_pointer, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian, unknown_length_sequence)
    header = struct;
    data_size = uint32(numel(file_data));
    dicom_undefined_length_tag_id = 4294967295;
    item_delim_tag = 4294893581;
    tag_list_index = 1;
    
    % Special case: the final tag is the item delimiter. We only care about
    % this if we are dealing with a sequence of unknown length. Otherwise
    % we want to ignore it because we want to terminate the parsing as soon
    % as we have processed the last tag we are interested in
    if unknown_length_sequence
        num_tags = numel(tag_list);
    else
        num_tags = numel(tag_list) - 1;
    end
    
    % This value will be set after the group length is read from the header
    end_of_meta_header = uint32(0);
    
    % These flags will be set after the transfer syntax tag is read
    change_in_transfer_syntax_required = false;
    flip_vr = false;
    flip_endian = false;
    
    % Parse tags
    while true
        % Check for end of file
        if (data_pointer + uint32(3)) > data_size
            return;
        end
        
        
        % From the 0003:0000 groups onwards, we need to allow for implicit VR
        % encoding, if that's what the transfer syntax specifies
        if change_in_transfer_syntax_required && (data_pointer > end_of_meta_header)
            change_in_transfer_syntax_required = false;
            if flip_vr
                flip_vr = false;
                is_explicit_vr = false;
            end
            if flip_endian
                is_little_endian = ~is_little_endian;
                flip_endian = false;
                file_endian_matches_computer_endian = ~file_endian_matches_computer_endian;
            end
        end        
        
        % Fetch the Dicom tag and convert into a 32-bit value
        if is_little_endian
            tag_32 = uint32(65536*(uint32(file_data(data_pointer)) + 256*uint32(file_data(data_pointer + 1))) + ...
                (uint32(file_data(data_pointer + 2)) + 256*uint32(file_data(data_pointer + 3))));
        else
            tag_32 = 65536*(uint32(file_data(data_pointer + 1)) + 256*uint32(file_data(data_pointer))) + ...
                (uint32(file_data(data_pointer + 3)) + 256*uint32(file_data(data_pointer + 2)));
        end
         
        % Item delimiter tag. This indicates the end of an item of
        % undefined length, so we return control to the calling
        % ReadSequence() method to process the next item.
        if tag_32 == item_delim_tag
            data_pointer = data_pointer + uint32(8);
            return
        end

        data_pointer = data_pointer + uint32(4);
                
        % Quit if there are no more tags to find
        while tag_32 > tag_list(tag_list_index)
            tag_list_index = tag_list_index + 1;
            if tag_list_index > num_tags
                return
            end
        end
        
        
        if is_explicit_vr
            % Work out the VR type
            vr_str = [char(file_data(data_pointer)), char(file_data(data_pointer + 1))];
            data_pointer = data_pointer + uint32(2);            
            
            % Compute the length
            switch vr_str
                case {'OB', 'OW', 'OF', 'SQ', 'UN'}
                    if file_endian_matches_computer_endian
                        length = typecast(file_data(data_pointer + 2 : data_pointer + 5), 'uint32');
                    else
                        length = typecast(file_data(data_pointer + 5 : -1 : data_pointer + 2), 'uint32');
                    end
                    data_pointer = data_pointer + uint32(6);
                case 'UT'
                    if file_endian_matches_computer_endian
                        length = typecast(file_data(data_pointer + 2 : data_pointer + 5), 'uint32');
                    else
                        length = typecast(file_data(data_pointer + 5 : -1 : data_pointer + 2), 'uint32');
                    end
                    data_pointer = data_pointer + uint32(6);
                otherwise
                    if is_little_endian
                        length = uint32(file_data(data_pointer)) + 256*uint32(file_data(data_pointer + 1));
                    else
                        length = 256*uint32(file_data(data_pointer)) + uint32(file_data(data_pointer + 1));
                    end
                    data_pointer = data_pointer + uint32(2);
            end
        else
            length = typecast(file_data(data_pointer : data_pointer + 3), 'uint32');
            data_pointer = data_pointer + uint32(4);
        end
        
        % Set a flag which indicates this length is undefined
        undefined_length = length == dicom_undefined_length_tag_id;
                
        % If this is a required tag, or if we don't know its length, then read and parse the data        
        if tag_32 == tag_list(tag_list_index) || undefined_length
            
            % For implicit VR we need to look up the VR from the tag map
            if ~is_explicit_vr
                if undefined_length && ~tag_map.isKey(tag_32)
                    vr_str = 'SQ'; % Undefined length only occurs for SQ and pixel data tags
                else
                    vr_str = tag_map(tag_32).VRType;
                end
            end
            
            % Fetch and parse the tag value data
            if undefined_length
                data_bytes = file_data(data_pointer : end);
            else
                data_bytes = file_data(data_pointer : data_pointer + length - 1);
            end
            [parsed_value, offset] = GetValueForTag(data_bytes, vr_str, file_endian_matches_computer_endian, tag_list, tag_map, is_explicit_vr, is_little_endian);
            
            if undefined_length
                length = offset;
            else
                if (length ~= offset)
                    disp(['Warning: length:' int2str(length) ' but offset:' int2str(offset)]);
                end
            end
            
            % Transfer syntax
            if tag_32 == 131088
                if strcmp(parsed_value, '1.2.840.10008.1.2') % Implicit VR little endian
                    flip_vr = true;
                    change_in_transfer_syntax_required = true;

                elseif strcmp(parsed_value, '1.2.840.10008.1.2.2') % Explicit VR big endian
                    flip_endian = true;
                    change_in_transfer_syntax_required = true;

                elseif strcmp(parsed_value, '1.2.840.10008.1.2.1.99') % Deflated Explicit VR Big Endian
                    change_in_transfer_syntax_required = true;
                    flip_endian = true;
                    
                 % Otherwise we assume explicit VR little endian
                end
            end

            % Get the length of the 0002 group from the first tag. We need to
            % know this so that we know when to change the transfer syntax.
            % Note this value excludes the length of the current tag
            if tag_32 == 131072 % FileMetaInformationGroupLength
                end_of_meta_header = data_pointer + uint32(length) + parsed_value  - 1;
            end
            
            % Add parsed value to our header
             if tag_32 == tag_list(tag_list_index)
                header.(tag_map(tag_32).Name) = parsed_value;
             end
        end
        
        data_pointer = data_pointer + uint32(length);
        
    end
    
end

% Only SQ, UN, OW, or OB can have unknown lengths
function [parsed_value, offset] = GetValueForTag(data_bytes, vr_type, file_endian_matches_computer_endian, tag_list, tag_map, is_explicit_vr, is_little_endian)
    offset = numel(data_bytes);
    switch(vr_type)
        case {'AE', 'AS', 'CS', 'DA', 'DT', 'LO', 'LT', 'SH', 'ST', 'TM', 'UI', 'UT'}
            parsed_value = deblank(char(data_bytes));
        case 'AT' % Attribute tag
            parsed_value = ReadNumber(data_bytes, 'uint16', file_endian_matches_computer_endian);
        case 'DS' % Decimal string
            parsed_value = sscanf(char(data_bytes), '%f\\');
        case {'FL', 'OF'} % Floating point single / Other float string
            parsed_value = ReadNumber(data_bytes, 'int32', file_endian_matches_computer_endian);
        case 'FD' % Floating point double
            parsed_value = ReadNumber(data_bytes, 'double', file_endian_matches_computer_endian);
        case 'IS' % Integer string
            parsed_value = int32(sscanf(char(data_bytes), '%f\\'));
        case 'OB' % Other byte string
            % NB may have unknown length
            parsed_value = ReadNumber(data_bytes, 'int8', file_endian_matches_computer_endian);
        case 'OW' % Other word string
            % NB may have unknown length
            parsed_value = ReadNumber(data_bytes, 'uint16', file_endian_matches_computer_endian);
        case 'PN'
            parsed_value = SplitPatientStrings(char(data_bytes));
        case 'SL' % Signed long
            parsed_value = ReadNumber(data_bytes, 'int32', file_endian_matches_computer_endian);
        case 'SQ' % Sequence of items
            % NB. may have unknown length
            [parsed_value, offset] = ReadSequence(data_bytes, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian);
        case 'SS' % Signed short
            parsed_value = ReadNumber(data_bytes, 'int16', file_endian_matches_computer_endian);
        case 'UL' % Unsigned long
            parsed_value = ReadNumber(data_bytes, 'uint32', file_endian_matches_computer_endian);
        case 'UN' % Unknown
            % may have unknown length
            parsed_value = ReadNumber(data_bytes, 'uint8', file_endian_matches_computer_endian);
        case 'US' % Unsigned short
            parsed_value = ReadNumber(data_bytes, 'uint16', file_endian_matches_computer_endian);
        otherwise
            error(['Unknown VR type:' vr_type]);
    end
end


function [parsed_value, data_pointer_offset] = ReadSequence(data_bytes, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian)
    parsed_value = [];
    if isempty(data_bytes)
        return;
    end
    
    dicom_undefined_length_tag_id = 4294967295;
    sequence_end_tag = 4294893789;
    start_item_tag = 4294893568;

    sequence_number = uint32(1);
    data_pointer_offset = uint32(1);
    
    data_bytes_end = numel(data_bytes);
    
    while data_pointer_offset <= data_bytes_end

        % Read item tag
        % Fetch the Dicom tag and convert into a 32-bit value
        if is_little_endian
            item_tag_32 = uint32(65536*(uint32(data_bytes(data_pointer_offset)) + 256*uint32(data_bytes(data_pointer_offset + 1))) + ...
                (uint32(data_bytes(data_pointer_offset + 2)) + 256*uint32(data_bytes(data_pointer_offset + 3))));
        else
            item_tag_32 = 65536*(uint32(data_bytes(data_pointer_offset + 1)) + 256*uint32(data_bytes(data_pointer_offset))) + ...
                (uint32(data_bytes(data_pointer_offset + 3)) + 256*uint32(data_bytes(data_pointer_offset + 2)));
        end

        if (item_tag_32 == sequence_end_tag)
            data_pointer_offset = data_pointer_offset + uint32(8);
            data_pointer_offset = data_pointer_offset - 1;
            return;
        end
        
        % Tag should be an item tag; if not, we assume the sequence is
        % finished and return to let he calling method parse the tag
        if (item_tag_32 ~= start_item_tag)
            error('Expected an ITEM tag');
        end
        
        % Read length
        if file_endian_matches_computer_endian
            item_length = typecast(data_bytes(data_pointer_offset + 4 : data_pointer_offset + 7), 'uint32');
        else
            item_length = typecast(data_bytes(data_pointer_offset + 7 : -1 : data_pointer_offset + 4), 'uint32');
        end
        
        unknown_sequence_length = item_length == dicom_undefined_length_tag_id;
        
        start_point = data_pointer_offset + 8;

        if unknown_sequence_length
            sub_data = data_bytes(start_point : end);
        else
            end_point = start_point + item_length - uint32(1);
            sub_data = data_bytes(start_point : end_point);
        end
        
        [header, is_little_endian, processed_data_pointer] = ParseFileData(sub_data, uint32(1), tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian, unknown_sequence_length);
        
        if unknown_sequence_length
            item_length = processed_data_pointer - 1;
            data_pointer_offset = start_point + item_length;
        else
            data_pointer_offset = start_point + item_length;
            if (item_length ~= processed_data_pointer - 1)
                disp(['Warning: item length:' int2str(item_length) ' but offset:' int2str(processed_data_pointer - 1)]);
            end
        end
        
        parsed_value.(['Item_' int2str(sequence_number)]) = header;
        sequence_number = sequence_number + uint32(1);
    end
    
end

function value = ReadNumber(data_bytes, data_type, file_endian_matches_computer_endian)
    value = typecast(data_bytes, data_type);
    if ~file_endian_matches_computer_endian
        value = swapbytes(value);
    end
    value = value';
end

function pn = SplitPatientStrings(char_data)
    if isempty(char_data)
        strings = {'', '', '', '', ''};
    else
        strings = deblank(regexp(char_data, regexptranslate('escape', '^'), 'split'));
    end
    pn = [];
    if numel(strings) > 0
        pn.FamilyName = strings{1};
        if numel(strings) > 1
            pn.GivenName = strings{2};
            if numel(strings) > 2
                pn.MiddleName = strings{3};
                if numel(strings) > 3
                    pn.NamePrefix = strings{4};
                    if numel(strings) > 4
                        pn.NameSuffix = strings{5};
                    end
                end
            end
        end
    end
end