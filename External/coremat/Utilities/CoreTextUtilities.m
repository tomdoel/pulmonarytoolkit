classdef CoreTextUtilities < handle
    % Utility functions related to strings
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %      


    methods (Static)
    
        function text = RemoveHtml(html_text)
            % Strips out HTML code from the provided string
            
            text = regexprep(html_text, '<.*?>', ' ');
            text = regexprep(text, '  ', ' ');
        end
        
        function file_name = MakeFilenameValid(file_name)
            % Strips out invalid characters from a filename
            
            file_name = regexprep(file_name, '  ', ' ');
            file_name(ismember(file_name, ' %*,.:;!?/<>\^%"')) = [];
        end
        
        function valid_field_name = CreateValidFieldName(original_field_name)
            % Strips out invalid characters from a filename
            
            valid_field_name = regexprep(char(original_field_name), '[^a-zA-Z0-9]', '_');
            if isempty(regexprep(valid_field_name(1), '[^a-zA-Z]', ''))
                valid_field_name = ['A' valid_field_name];
            end
        end
        
        function [sorted_filenames, sorted_indices] = SortFilenames(original_filenames)
            % Sorts a list of filenames, taking into account numbers
            
            if isempty(original_filenames)
                sorted_filenames = [];
                sorted_indices = [];
                return;
            end
            
            if isa(original_filenames{1}, 'CoreFilename')
                filenames = CoreContainerUtilities.GetFieldValuesFromSet(original_filenames, 'Name');
            else
                filenames = original_filenames;
            end
            
            
            % Determine the maximum number of consecutive digits across all of
            % the filenames
            [start_indices, end_indices] = regexp(filenames,'\d+','start','end');
            max_digits = 0;
            for filename_index = 1 : length(start_indices)
                string_lengths = 1 + end_indices{filename_index} - start_indices{filename_index};
                if ~isempty(string_lengths)
                    max_digits = max(max_digits, max(string_lengths));
                end
            end
            
            % Format each sequence of numbers into a fixed width field, so that
            % sorting will correctly order numbered files which don't have
            % leading zeros
            sprintf_field = ['%' int2str(max_digits) 'd']; %#ok<NASGU>
            reformatted_filenames = regexprep(filenames, '(\d+)', '${ sprintf(sprintf_field, (str2num(($1))) ) }');
            
            % Finally perform the sorting on the reformatted filenames
            [~, sorted_indices] = sort(reformatted_filenames);
            sorted_filenames = original_filenames(sorted_indices');
        end
        
        function filenames_stripped = StripFileparts(filenames)
            % Returns just the main filenames, removing the path and filetype
            
            cell_input = iscell(filenames);
            if ~cell_input
                filenames = {filenames};
            end
            filenames_stripped = [];
            for index = 1 : numel(filenames)
                [~, file_name, ~] = fileparts(filenames{index});
                filenames_stripped{index} = file_name;
            end
            if ~cell_input
                filenames_stripped = filenames_stripped{1};
            end
        end
        
        function adjustedString = RemoveNonprintableCharacters(string)
            % Removes special characters from a string
            
            if isempty(string)
                adjustedString = string;
            else
                adjustedString = string(uint8(string) >= 32);
            end
        end
        
        function adjustedString = RemoveNonprintableCharactersAndStrip(string)
            % Removes special characters from a string
            
            if isempty(string)
                adjustedString = string;
            elseif ischar(string)
                adjustedString = strtrim(string(uint8(string) >= 32));
            elseif isstruct(string)
                adjustedString = struct;
                for field = fieldnames(string)
                    adjustedString.(field{1}) = CoreTextUtilities.RemoveNonprintableCharactersAndStrip(string.(field{1}));
                end
            elseif iscell(string)
                adjustedString = cellfun(@CoreTextUtilities.RemoveNonprintableCharactersAndStrip, string, 'UniformOutput', false);
            else
                adjustedString = string;
            end
        end
        
        function [first, last] = SplitAtLastDelimiter(string, delimiter)
            index = find(string == delimiter, 1, 'last');
            if isempty(index)
                first = string;
                last = '';
            else
                first = string(1:index - 1);
                last = string(index + 1:end);
            end
        end
        
        function is_equal = CompareStringsNoCase(st1, st2)
            % Compare strings ignoring case, mnonprintable characters and
            % leading/trailing spaces
            is_equal = strcmpi(CoreTextUtilities.RemoveNonprintableCharactersAndStrip(st1), CoreTextUtilities.RemoveNonprintableCharactersAndStrip(st2)); 
        end
        
        function alphanum = GetAlphaNumString(string)
            % Returns a simplified string containing only uppercase and
            % numerals
            if iscell(string)
                alphanum = cellfun(@CoreTextUtilities.GetAlphaNumString, string, 'UniformOutput', false);
            else
                alphanum = string(isstrprop(string, 'alphanum'));
            end
        end
        
        function basic = GetBasicString(string)
            % Returns a simplified string containing only uppercase and
            % numerals
            basic = upper(CoreTextUtilities.GetAlphaNumString(string));
        end

    end
end

