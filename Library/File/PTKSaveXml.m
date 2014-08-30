function PTKSaveXml(data, name, file_name, reporting)
    % PTKSaveXml. Saves a data structure as an XML file
    %
    %     PTKSaveXml saves data into an XML file. The data may include arrays,
    %     cell arrays, structures, maps and classes which support serialisation.
    %
    %     Syntax:
    %         PTKSaveXml(data, name, file_name, reporting)
    %
    %             data - the root object of the data to store. Can be a value, a class, a structure, map or cell array
    %             name - the name of the root object 
    %             file_name - a PTKFilename or character array containing the path and filename
    %             reporting - object of type PTKReportingInterface for error reporting
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %            
    
    xml_doc_node = com.mathworks.xml.XMLUtils.createDocument('PTK');
    xml_root_element = xml_doc_node.getDocumentElement;
    xml_root_element.setAttribute('PTKVersion', PTKSoftwareInfo.Version);
    xml_root_element.setAttribute('XMLVersion', PTKSoftwareInfo.XMLVersion);
    
    serialised_node = CreateNodeForPropertyMatrix('PTKSerialised', name, data, xml_doc_node, reporting);
    
    xml_root_element.appendChild(serialised_node);
    xml_doc_node.appendChild(xml_doc_node.createComment('TD Pulmonary Toolkit. Automatically generated XML file. Code by Tom Doel 2014'));
    
    if isa(file_name, 'PTKFilename')
        file_name = file_name.FullFile;
    end
    
    xmlwrite(file_name, xml_doc_node);
end

function node = AddNodesForStruct(node, data, xml_doc_node, reporting)
    field_list = fieldnames(data);
    for i = 1 : length(field_list)
        next_field = field_list{i};
        node.appendChild(CreateNodeForPropertyMatrix('Field', next_field, data.(next_field), xml_doc_node, reporting));
    end
end

function node = AddNodesForClass(node, data, xml_doc_node, reporting)
    mc = metaclass(data);
    enumeration_list = mc.EnumerationMemberList;
    if ~isempty(enumeration_list)
        node.setAttribute('Enumeration', char(data));
        node.appendChild(CreateTextNode(char(data), xml_doc_node, reporting));
    end
    
    class_properties = PTKContainerUtilities.GetFieldValuesFromSet(mc.Properties, 'Name');
    public_properties = properties(data);
    property_list = union(class_properties, public_properties);
    for i = 1 : length(property_list)
        next_property = property_list{i};
        if ~strcmp(next_property, 'EventListeners')
            node.appendChild(CreateNodeForPropertyMatrix('Property', next_property, data.(next_property), xml_doc_node, reporting));
        end
    end
end

function property_node = CreateNodeForPropertyMatrix(node_name, property_name, property_value, xml_doc_node, reporting)
    
    % Create the node for this value
    property_node = xml_doc_node.createElement(node_name);
    
    % Store class name as attributes
    property_node.setAttribute('Name', property_name);
    
    property_node = AddValuesToNode(property_node, property_value, xml_doc_node, reporting);
end

function node = AddValuesToNode(node, value, xml_doc_node, reporting)
    
    value_class = class(value);
    matrix_size = size(value);
    
    node.setAttribute('Class', value_class);
    
    % We split char arrays into 1D strings along the horizontal dimension
    size_excluding_dimension_2 = matrix_size;
    size_excluding_dimension_2(2) = [];
    
    % To simplify XML output, if the values form a horizontal array then we don't
    % write out the size
    if ~all(size_excluding_dimension_2 == 1)
        node.setAttribute('Size', int2str(matrix_size));
    end
    
    % We write out matrices as a horizontal linear array
    if isa(value, 'containers.Map')
        linear_values = value;
    else
        linear_values = value(:)';
    end
    
    if ischar(value)
        % Strings
        node.appendChild(CreateTextNode(linear_values, xml_doc_node, reporting));
        
    elseif isnumeric(value)
        % Numeric types
        node.appendChild(CreateNumericNode(linear_values, xml_doc_node, reporting));
        
    elseif islogical(value)
        % Boolean types
        node.appendChild(CreateLogicalNode(linear_values, xml_doc_node, reporting));

    elseif iscell(value)
        % Cell array
        if numel(value) == 1
            % We can omit the index if there is only one cell
            node.appendChild(CreateCellValueNode(value{1}, [], xml_doc_node, reporting));
        else
            for cell_array_index = 1 : numel(value)
                node.appendChild(CreateCellValueNode(value{cell_array_index}, cell_array_index, xml_doc_node, reporting));
            end
        end

    elseif isstruct(value)
        % Structure
        if numel(value) == 1
            % We can omit the index if there is only one object
            node = AddNodesForStruct(node, value, xml_doc_node, reporting);
        else
            % For an array of objects, add a class value node for each one
            for array_index = 1 : numel(value)
                node.appendChild(CreateStructArrayElementNode(value(array_index), array_index, xml_doc_node, reporting));
            end
        end
        
        node = AddNodesForStruct(node, value, xml_doc_node, reporting);

    elseif isa(value, 'containers.Map')
        % Map
        keys = value.keys;
        for index = 1 : length(keys);
            key = keys{index};
            node.appendChild(CreateMapNode(value(key), key, xml_doc_node, reporting));
        end
        
    elseif ishghandle(value)
        reporting.Error('PTKSaveXml:UnsupportedClass', 'Cannot export handle graphics objects to XML');
            
    elseif isjava(value)
        reporting.Error('PTKSaveXml:UnsupportedClass', 'Cannot export java objects to XML');

    else
        % Other class
        if numel(value) == 1
            % We can omit the index if there is only one object
            node = AddNodesForClass(node, value, xml_doc_node, reporting);
        else
            % For an array of objects, add a class value node for each one
            for array_index = 1 : numel(value)
                node.appendChild(CreateClassArrayElementNode(value(array_index), array_index, parent_class, xml_doc_node, reporting));
            end
        end
    end
end

function node = CreateTextNode(property_value, xml_doc_node, reporting)
    node = xml_doc_node.createTextNode(property_value);
end

function node = CreateNumericNode(property_value, xml_doc_node, reporting)
    node = xml_doc_node.createTextNode(num2str(property_value));
end

function node = CreateLogicalNode(property_value, xml_doc_node, reporting)
    node = xml_doc_node.createTextNode(num2str(double(property_value)));
end

function value_node = CreateClassArrayElementNode(value, property_index, parent_class, xml_doc_node, reporting)
    value_node = xml_doc_node.createElement('ClassArrayElement');
    value_node.setAttribute('Index', int2str(property_index));
    
    % If the element's class is different from the parent, then store it
    value_class = class(value);
    if ~strcmp(parent_class, value_class)
        value_node.setAttribute('Class', value_class);
    end
    value_node = AddNodesForClass(value_node, value, xml_doc_node, reporting);
end

function value_node = CreateStructArrayElementNode(value, property_index, xml_doc_node, reporting)
    value_node = xml_doc_node.createElement('StructArrayElement');
    value_node.setAttribute('Index', int2str(property_index));    
    value_node = AddNodesForStruct(value_node, value, xml_doc_node, reporting);
end

function value_node = CreateCellValueNode(property_value, property_index, xml_doc_node, reporting)
    value_node = xml_doc_node.createElement('CellValue');
    if ~isempty(property_index)
        value_node.setAttribute('Index', int2str(property_index));
    end
    AddValuesToNode(value_node, property_value, xml_doc_node, reporting);
end

function map_node = CreateMapNode(value, key, xml_doc_node, reporting)
    map_node = xml_doc_node.createElement('MapValue');
    map_node.setAttribute('KeyClass', class(key));
    if isnumeric(key)
        key_str = int2str(key);
    else
        key_str = key;
    end
    map_node.setAttribute('Key', key_str);
    AddValuesToNode(map_node, value, xml_doc_node, reporting);
end