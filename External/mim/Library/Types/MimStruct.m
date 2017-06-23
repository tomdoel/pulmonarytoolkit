classdef MimStruct < dynamicprops
    % MimStruct. Holds multiple properties
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        

    methods
        function obj = MimStruct(varargin)
            obj = obj@dynamicprops();
            if ~isempty(varargin)
                for i = 1 : 2 : numel(varargin)
                    obj.AddField(varargin{i}, varargin{i + 1});
                end
            end
        end
    
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
            if ~isa(other_struct, 'MimStruct')
                reporting.Error('MimStruct:NotMimStruct', 'The argument passed to Merge() was not of type MimStruct');
            end

            field_name_list = other_struct.GetListOfProperties;
            for field_index = 1 : length(field_name_list)
                field_name = field_name_list{field_index};
                obj.AddField(field_name, other_struct.(field_name));
            end
        end
        
        function result = GetFirstResult(obj)
            result = obj;
            while isa(result, 'MimStruct')
                result_properties = properties(result);
                result = result.(result_properties{1});
            end
        end
        
        function is_equal = isequal(obj, other)
            % Custom compare method because isequal does not work with dynamicprops
            is_equal = false;
            if ~isa(other, 'MimStruct')
                return
            else
                p1 = properties(obj);
                p2 = properties(other);
                if ~isequal(sort(p1), sort(p2))
                    return
                end
                for p = p1'
                    if ~isequal(obj.(p{1}), other.(p{1}))
                        return
                    end
                end
            end
            is_equal = true;
        end
    end
end