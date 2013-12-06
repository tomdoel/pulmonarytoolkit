function header = PTKFastReadDicomHeader(file_path, file_name, dictionary, reporting)
    % PTKFastReadDicomHeader. Reads in metainformation from a Dicom file.
    %
    % Usage:
    %     header = PTKFastReadDicomHeader(file_path, file_name, tag_list, tag_map, reporting)
    %
    %     file_path, file_name: path and filename of the Dicom file to read
    %
    %     dictionary - an object of class PTKDicomDictionary containing the tags
    %         to fetch.
    %
    %     reporting - a PTKReporting object for error reporting
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    if nargin < 3
        reporting = PTKReportingDefault;
    end
    
    tag_map = dictionary.TagMap;
    tag_list = dictionary.TagList;
    
    % ToDo: we need to deal with tags of unknown length
   
    [is_dicom, header] = ReadDicomFile(file_path, file_name, tag_list, tag_map, reporting);    
end

function [is_dicom, header] = ReadDicomFile(file_path, file_name, tag_list, tag_map, reporting)
    
    % Read the data into a local byte array
    full_file_name = fullfile(file_path, file_name);
    file_id = fopen(full_file_name, 'r');
    file_data = fread(file_id, 'uint8=>uint8');
    file_data = file_data';
    fclose(file_id);
    
    % Check this is a Dicom file
    dicom_chars = char(file_data(129:132));
    is_dicom = strcmp(dicom_chars, 'DICM');
    if ~is_dicom
        header = [];
        return;
    end
    
    data_pointer = uint32(133);
    computer_endian = PTKSystemUtilities.GetComputerEndian;
    
    % All tags up to group (0002) are in explicit VR little endian.
    % After that we change to implicit VR and big endian if necessary
    is_explicit_vr = true;
    is_little_endian = true;
    file_endian_matches_computer_endian = (computer_endian == PTKEndian.LittleEndian);
    
    header = ParseFileData(file_data, data_pointer, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian, reporting);
end

function header = ParseFileData(file_data, data_pointer, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian, reporting)
    header = struct;
    data_size = uint32(numel(file_data));
    dicom_undefined_length_tag_id = 4294967295;
    tag_list_index = 1;
    num_tags = numel(tag_list);
    
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
        
        % We can't deal with undefined length
        if length == dicom_undefined_length_tag_id
            error('Cannot process tags with undefined length');
        end
                
        % If this is a required tag then read and parse the data        
        if tag_32 == tag_list(tag_list_index)
            
            % For implicit VR we need to look up the VR from the tag map
            if ~is_explicit_vr
                vr_str = tag_map(tag_32).VRType;
            end
            
            % Fetch and parse the tag value data
            data_bytes = file_data(data_pointer : data_pointer + length - 1);
            parsed_value = GetValueForTag(data_bytes, vr_str, file_endian_matches_computer_endian, tag_list, tag_map, is_explicit_vr, is_little_endian);
            
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
            header.(tag_map(tag_32).Name) = parsed_value;
        end
        
        data_pointer = data_pointer + uint32(length);
        
    end
    
end

% Only SQ, UN, OW, or OB can have unknown lengths
function parsed_value = GetValueForTag(data_bytes, vr_type, file_endian_matches_computer_endian, tag_list, tag_map, is_explicit_vr, is_little_endian)
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
        case 'OB' % Other byte strng
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
            parsed_value = ReadSequence(data_bytes, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian);
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


function parsed_value = ReadSequence(data_bytes, tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian)
    parsed_value = [];
    if isempty(data_bytes)
        return;
    end
    
    dicom_undefined_length_tag_id = 4294967295;    
    sequence_number = uint32(1);
    data_pointer = uint32(1);
    
    data_bytes_end = numel(data_bytes);
    
    while data_pointer <= data_bytes_end

        % Read length
        if file_endian_matches_computer_endian
            item_length = typecast(data_bytes(data_pointer + 4 : data_pointer + 7), 'uint32');
        else
            item_length = typecast(data_bytes(data_pointer + 7 : -1 : data_pointer + 4), 'uint32');
        end
        
        if item_length == dicom_undefined_length_tag_id
            disp('Cannot process sequence tags with undefined length.');
            parsed_value = [];
            return;
        end
        
        start_point = data_pointer + 8;
        end_point = start_point + item_length - uint32(1);
        
        header = ParseFileData(data_bytes(start_point : end_point), uint32(1), tag_list, tag_map, is_explicit_vr, is_little_endian, file_endian_matches_computer_endian);
        data_pointer = data_pointer + item_length + uint32(8);
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