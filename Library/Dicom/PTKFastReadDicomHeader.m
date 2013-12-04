function header = PTKFastReadDicomHeader(file_path, file_name, tag_list, tag_map, reporting)
    % PTKFastReadDicomHeader.
    %
    %
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
    
    % ToDo: May fail if a big endian file has tags in the (0002) group after the transfer syntax uid
    % ToDo: we need to deal with SQ tags
    % ToDo: we need to deal with tags of unknown length
   
    [is_dicom, header] = ReadDicomFile(file_path, file_name, tag_list, tag_map);    
end

function [is_dicom, header] = ReadDicomFile(file_path, file_name, tag_list, tag_map)
    
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
    
    
    header = ParseFileData(file_data, data_pointer, tag_list, tag_map, computer_endian);
end

function header = ParseFileData(file_data, data_pointer, tag_list, tag_map, computer_endian)
    header = struct;
    data_size = uint32(numel(file_data));
    dicom_undefined_length_tag_id = 4294967295;
    tag_list_index = 1;
    next_tag_to_find = tag_list(tag_list_index);
    
    
    % All tags up to group (0002) are in explicit VR little endian.
    % After that we change to implicit VR and big endian if necessary
    is_explicit_vr = true;
    flip_vr = false;
    flip_endian = (computer_endian ~= PTKEndian.LittleEndian);
    
    % Parse tags
    while true
        % Check for end of file
        if (data_pointer + uint32(3)) > data_size
            return;
        end
        
        % Fetch the Dicom tag as a pair of uint16s
        if flip_endian
            tag_32 = 65536*(uint32(file_data(data_pointer + 1)) + 256*uint32(file_data(data_pointer))) + ...
                (uint32(file_data(data_pointer + 3)) + 256*uint32(file_data(data_pointer + 2)));
        else
            tag_32 = uint32(65536*(uint32(file_data(data_pointer)) + 256*uint32(file_data(data_pointer + 1))) + ...
                (uint32(file_data(data_pointer + 2)) + 256*uint32(file_data(data_pointer + 3))));
        end
        data_pointer = data_pointer + uint32(4);
        
        % Quit if there are no more tags to find
        while tag_32 > next_tag_to_find
            tag_list_index = tag_list_index + 1;
            if tag_list_index > numel(tag_list)
                return
            end
            next_tag_to_find = tag_list(tag_list_index);
        end
        
        % From the 0003:0000 groups onwards, we need to allow for implicit VR
        % encoding, if that's what the transfer syntax specifies
        if flip_vr && (tag_32 > 196607)
            is_explicit_vr = false;
            flip_vr = false;
        end
        
        
        if is_explicit_vr
            % Work out the VR type
            vr_str = [char(file_data(data_pointer)), char(file_data(data_pointer + 1))];
            data_pointer = data_pointer + uint32(2);            
            
            % Compute the length
            switch vr_str
                case {'OB', 'OW', 'OF', 'SQ', 'UN'}
                    if flip_endian
                        length = typecast(file_data(data_pointer + 5 : -1 : data_pointer + 2), 'uint32');
                    else
                        length = typecast(file_data(data_pointer + 2 : data_pointer + 5), 'uint32');
                    end
                    data_pointer = data_pointer + uint32(6);
                case 'UT'
                    if flip_endian
                        length = typecast(file_data(data_pointer + 5 : -1 : data_pointer + 2), 'uint32');
                    else
                        length = typecast(file_data(data_pointer + 2 : data_pointer + 5), 'uint32');
                    end
                    data_pointer = data_pointer + uint32(6);
                otherwise
                    if flip_endian
                        length = 256*uint32(file_data(data_pointer)) + uint32(file_data(data_pointer + 1));
                    else
                        length = uint32(file_data(data_pointer)) + 256*uint32(file_data(data_pointer + 1));
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
        if tag_32 == next_tag_to_find
            
            % For implicit VR we need to look up the VR from the tag map
            if ~is_explicit_vr
                vr_str = tag_map(tag_32).VRType;
            end
            
            % Fetch and parse the tag value data
            data_bytes = file_data(data_pointer : data_pointer + length - 1);
            parsed_value = GetValueForTag(data_bytes, vr_str, flip_endian);
            
            if tag_32 == 131088
                if strcmp(parsed_value, '1.2.840.10008.1.2') % Implicit VR little endian
                    flip_vr = true;
                elseif strcmp(parsed_value, '1.2.840.10008.1.2.2') % Explicit VR big endian
                    flip_endian = ~flip_endian;
                elseif strcmp(parsed_value, '1.2.840.10008.1.2.1.99') % Deflated explicit VR big endian
                    flip_endian = ~flip_endian;
                else % explicit VR little endian
                end
            end
                
                
            % Add parsed value to our header
            if ~isempty(parsed_value)
                header.(tag_map(tag_32).Name) = parsed_value;
            end            
        end
        
        data_pointer = data_pointer + uint32(length);
    end
end

function [value_field_length_bytes, value_field_length_type, reserved_bytes_length] = GetLengthParams(vr_str, is_explicit_vr)
    if is_explicit_vr
        switch vr_str
            case {'OB', 'OW', 'OF', 'SQ', 'UN'}
                reserved_bytes_length = 2;
                value_field_length_bytes = 4;
                value_field_length_type = 'uint32';
            case 'UT'
                reserved_bytes_length = 2;
                value_field_length_bytes = 4;
                value_field_length_type = 'uint32';
            otherwise
                reserved_bytes_length = 0;
                value_field_length_bytes = 2;
                value_field_length_type = 'uint16';
        end
    else
        reserved_bytes_length = 0;
        value_field_length_bytes = 4;
        value_field_length_type = 'uint32';
    end
end

% Only SQ, UN, OW, or OB can have unknown lengths
function parsed_value = GetValueForTag(data_bytes, vr_type, flip_endian)
    switch(vr_type)
        case {'AE', 'AS', 'CS', 'DA', 'DT', 'LO', 'LT', 'SH', 'ST', 'TM', 'UI', 'UT'}
            parsed_value = deblank(char(data_bytes));
        case 'AT' % Attribute tag
            parsed_value = ReadNumber(data_bytes, 'uint16', flip_endian);
        case 'DS' % Decimal string
            parsed_value = sscanf(char(data_bytes), '%f\\');
        case {'FL', 'OF'} % Floating point single / Other float string
            parsed_value = ReadNumber(data_bytes, 'int32', flip_endian);
        case 'FD' % Floating point double
            parsed_value = ReadNumber(data_bytes, 'double', flip_endian);
        case 'IS' % Integer string
            parsed_value = int32(sscanf(char(data_bytes), '%f\\'));
        case 'OB' % Other byte strng
            % NB may have unknown length
            parsed_value = ReadNumber(data_bytes, 'int8', flip_endian);
        case 'OW' % Other word string
            % NB may have unknown length
            parsed_value = ReadNumber(data_bytes, 'uint16', flip_endian);
        case 'PN'
            parsed_value = SplitPatientStrings(char(data_bytes));
        case 'SL' % Signed long
            parsed_value = ReadNumber(data_bytes, 'int32', flip_endian);
        case 'SQ' % Sequence of items
            disp('Warning: SQ tag is not currently parsed');
            % NB. may have unknown length
            parsed_value = ReadNumber(data_bytes, 'uint8', flip_endian);
        case 'SS' % Signed short
            parsed_value = ReadNumber(data_bytes, 'int16', flip_endian);
        case 'UL' % Unsigned long
            parsed_value = ReadNumber(data_bytes, 'uint32', flip_endian);
        case 'UN' % Unknown
            % may have unknown length
            parsed_value = ReadNumber(data_bytes, 'uint8', flip_endian);
        case 'US' % Unsigned short
            parsed_value = ReadNumber(data_bytes, 'uint16', flip_endian);
        otherwise
            error(['Unknown VR type:' vr_type]);
    end
end

function value = ReadNumber(data_bytes, data_type, flip_endian)
    value = typecast(data_bytes, data_type);
    if flip_endian
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