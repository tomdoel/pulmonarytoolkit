classdef TDTextUtilities < handle
    % TDTextUtilities. Utility functions related to strings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        


    methods (Static)
    
        % Strips out HTML code from the provided string
        function text = RemoveHtml(html_text)
            text = regexprep(html_text, '<.*?>', ' ');
            text = regexprep(text, '  ', ' ');
        end
        
        % Sorts a list of filenames, taking into account numbers
        function sorted_filenames = SortFilenames(filenames)
            
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
            sorted_filenames = filenames(sorted_indices');
        end
    end
    
end

