function data = PTKLoadXml(file_name, reporting)
    % PTKLoadXml. Loads data structure from an XML file
    %
    %     PTKLoadXml loads data which has been serialised to an XML file using
    %     PTKSaveXml. The data may include arrays, cell arrays, structures, maps and
    %     classes which support serialisation.
    %
    %     Syntax:
    %         data = PTKLoadXml(file_name, reporting);
    %
    %             file_name - a PTKFilename or character array containing the path and filename
    %             reporting - object of type PTKReportingInterface for error reporting
    %
    %             data - a structure containing all the data which has been loaded
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if isa(file_name, 'PTKFilename')
        file_name = file_name.FullFile;
    end
    
    xml_doc_node = xmlread(file_name);
    data = ParseXmlFile(xml_doc_node, reporting);
end

function data = ParseXmlFile(xml_doc_node, reporting)
    children = GetChildNodes(xml_doc_node);
    for child = children
        next_child = child{1};
        node_name = GetNodeName(next_child);
        if strcmp(node_name, 'PTK')
            attributes = GetAttributes(next_child);
            xml_version = attributes.XMLVersion;
            if ~strcmp(xml_version, PTKSoftwareInfo.XMLVersion)
                reporting.Error('PTKLoadXml:XMLVersionMismatch', 'This XML file was created with a newer version of the Pulmonary Toolkit.');
            end
            data = ParsePTK(next_child);
        end
    end
end

function data = ParsePTK(xml_node)
    data = [];
    children = GetChildNodes(xml_node);
    for child = children
        next_child = child{1};
        node_name = GetNodeName(next_child);
        if strcmp(node_name, 'PTKSerialised')
            [child_name, child_data] = ParseProperty(next_child);
            data.(child_name) = child_data;
        end
    end
end

function empty_class = GetEmptyClass(class_name)
    empty_class = feval([class_name, '.empty']);
end

function data = ParseClass(class_name, xml_node)
    attributes = GetAttributes(xml_node);
    
    if isfield(attributes, 'Enumeration');
        % Initialise enumerations using value
        enum_value_string = char(GetData(xml_node));
        data = eval([class_name, '.', enum_value_string]);
        
    elseif isempty(class_name)
        % Create empty structure
        data = struct;
        
    else
        % Create empty class
        data = feval(class_name);
    end
    
    child_nodes = GetChildNodes(xml_node);
    for child_node = child_nodes
        next_child = child_node{1};
        node_name = GetNodeName(next_child);
        if strcmp(node_name, 'Property')
            [property_name, property_value] = ParseProperty(next_child);
            if ~isprop(data, property_name) && isa(data, 'dynamicprops')
                data.addprop(property_name);
            end
            data.(property_name) = property_value;
        end
    end
end

function data = ParseStruct(xml_node)
    
    % Create empty structure
    data = struct;
    
    child_nodes = GetChildNodes(xml_node);
    for child_node = child_nodes
        next_child = child_node{1};
        node_name = GetNodeName(next_child);
        if strcmp(node_name, 'Field')
            [property_name, property_value] = ParseProperty(next_child);
            data.(property_name) = property_value;
        end
    end
end


function class_array = ParseClassArray(class_name, xml_node)
    
    data = GetData(xml_node);
    
    if isempty(data)
        
        % Create an empty array
        class_array = GetEmptyClass(class_name);
        
        % Iterate through the child nodes, looking for class element nodes
        child_nodes = GetChildNodes(xml_node);
        for child_node = child_nodes
            next_child = child_node{1};
            node_name = GetNodeName(next_child);
            if strcmp(node_name, 'ClassArrayElement')
                child_attributes = GetAttributes(next_child);
                array_index = str2double(child_attributes.Index);
                class_array(array_index) = ParseClass(class_name, next_child);
            end
        end
    else
        class_array = ParseClass(class_name, xml_node);
    end
end


function struct_array = ParseStructArray(xml_node)
    
    data = GetData(xml_node);
    
    if isempty(data)
        
        % Create an empty array
        struct_array = struct;
        
        % Iterate through the child nodes, looking for class element nodes
        child_nodes = GetChildNodes(xml_node);
        for child_node = child_nodes
            next_child = child_node{1};
            node_name = GetNodeName(next_child);
            if strcmp(node_name, 'StructArrayElement')
                child_attributes = GetAttributes(next_child);
                array_index = str2double(child_attributes.Index);
                struct_array(array_index) = ParseStruct(next_child);
            end
        end
    else
        struct_array = ParseStruct(xml_node);
    end
end


function cell_array = ParseCellArray(xml_node)
    
    % Create an empty cell array
    cell_array = {};
    
    % Iterate through the child nodes, looking for cell element nodes
    child_nodes = GetChildNodes(xml_node);
    for child_node = child_nodes
        next_child = child_node{1};
        node_name = GetNodeName(next_child);
        if strcmp(node_name, 'CellValue')
            child_attributes = GetAttributes(next_child);
            if isfield(child_attributes, 'Index')
                array_index = str2double(child_attributes.Index);
                cell_array{array_index} = ParsePropertyValues(child_attributes, next_child);
            else
                cell_array = ParsePropertyValues(child_attributes, next_child);
            end
        end
    end
end

function map = ParseMap(xml_node)
    
    % Create an empty map
    map = containers.Map;
    
    % Iterate through the child nodes, looking for cell element nodes
    child_nodes = GetChildNodes(xml_node);
    for child_node = child_nodes
        next_child = child_node{1};
        node_name = GetNodeName(next_child);
        if strcmp(node_name, 'MapValue')
            child_attributes = GetAttributes(next_child);
            
            % Fetch the key and convert to the correct type. Map keys are character strings
            % or numeric
            key_string = child_attributes.Key;
            key_class = child_attributes.KeyClass;
            if strcmp(key_class, 'char')
                key = key_string;
            else
                key = typecast(str2double(key_string), key_class);
            end
            
            map(key) = ParsePropertyValues(child_attributes, next_child);
        end
    end
end





function [property_name, property_value] = ParseProperty(xml_node)
    attributes = GetAttributes(xml_node);
    property_name = attributes.Name;
    property_value = ParsePropertyValues(attributes, xml_node);
end

function property_value = ParsePropertyValues(attributes, xml_node)
    
    if isfield(attributes, 'Size')
        property_size = str2num(attributes.Size); %#ok<ST2NM>
    else
        property_size = [];
    end
    property_class = attributes.Class;
    data = GetData(xml_node);
    property_values_linear = GetValues(data, property_class, xml_node);
    
    if isempty(property_size) && (numel(property_values_linear) == 1)
        property_value = property_values_linear;
    else
        if isempty(property_size)
            property_size = [1, numel(property_values_linear)];
        end
        if strcmp(property_class, 'containers.Map');
            property_value = property_values_linear;
        else
            % Reshape the linear values to match the original matrix size. Note that map
            % objects cannot be part of an array
            property_value = reshape(property_values_linear, property_size);
        end
    end
end

function property_value = GetValues(data, property_class, xml_node)
    
    switch property_class
        case 'double'
            property_value = double(str2num(data));
        case 'char'
            property_value = char(data);
        case 'single'
            property_value = single(str2num(data));
        case 'int8'
            property_value = int8(str2num(data));
        case 'uint8'
            property_value = uint8(str2num(data));
        case 'int16'
            property_value = int16(str2num(data));
        case 'uint16'
            property_value = uint16(str2num(data));
        case 'int32'
            property_value = int32(str2num(data));
        case 'uint32'
            property_value = uint32(str2num(data));
        case 'int64'
            property_value = int64(str2num(data));
        case 'uint64'
            property_value = uint64(str2num(data));
        case 'logical'
            property_value = logical(str2num(data));
        case 'struct'
            property_value = ParseStructArray(xml_node);
        case 'cell'
            property_value = ParseCellArray(xml_node);
        case 'containers.Map'
            property_value = ParseMap(xml_node);
            
        otherwise
            property_value = ParseClassArray(property_class, xml_node);
            
    end
    
end

function attributes = GetAttributes(xml_node)
    attributes = [];
    if xml_node.hasAttributes
        node_attributes = xml_node.getAttributes;
        for attribute_index = 0 : node_attributes.getLength - 1
            attribute = node_attributes.item(attribute_index);
            attributes.(char(attribute.getName)) = char(attribute.getValue);
        end
    end
end

function node_name = GetNodeName(xml_node)
    node_name = char(xml_node.getNodeName);
end

function child = GetFirstChildNode(xml_node)
    child_nodes = xml_node.getChildNodes;
    child = child_nodes.item(0);
end

function children = GetChildNodes(xml_node)
    children = {};
    if xml_node.hasChildNodes
        child_nodes = xml_node.getChildNodes;
        for index = 0 : child_nodes.getLength - 1
            children{index + 1} = child_nodes.item(index);
        end
    end
end

function data = GetData(xml_node)
    data = '';
    first_node = GetFirstChildNode(xml_node);
    if any(strcmp(methods(first_node), 'getData'))
        data = first_node.getData;
    end
end
