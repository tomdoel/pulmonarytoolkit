classdef PTKStruct < dynamicprops
    % PTKStruct. Holds multiple properties
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    methods
        function AddField(obj, field_name, field_value)
            obj.addprop(char(field_name));
            obj.(field_name) = field_value;
        end
        
        function field_name_list = GetListOfFields(obj)
            field_name_list = properties(obj);
        end
        
        function is_a_field = IsField(obj, field_name)
            is_a_field = isprop(obj, char(field_name));
        end
        
        function Merge(obj, other_struct, reporting)
            if ~isa(other_struct, 'PTKStruct')
                reporting.Error('PTKStruct:NotPTKStruct', 'The argument passed to Merge() was not of type PTKStruct');
            end

            field_name_list = other_struct.GetListOfProperties;
            for field_index = 1 : length(field_name_list)
                field_name = field_name_list{field_index};
                obj.AddField(field_name, other_struct.(field_name));
            end
        end
    end
end