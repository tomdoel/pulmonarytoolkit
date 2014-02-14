classdef PTKGraphUtilities
    % PTKGraphUtilities. Utility functions related to graph plotting
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    methods (Static)

        function [tick_spacing, min_value, max_value] = GetOptimalTickSpacing(min_value, max_value)
            % Returns the tick spacing required that will look good on printed graphs
            
            range = max_value - min_value;
            
            power_of_10 = log10(range);
            frac = power_of_10 - floor(power_of_10);
            power_of_10 = floor(power_of_10);
            
            % For fractional values lower than about 3, we lower the power of 10
            if frac < 0.477
                power_of_10 = power_of_10 - 1;
                if frac < 0.1
                    tick_multiplier = 2;
                else
                    tick_multiplier = 5;
                end
            else
                if frac > 0.7
                    tick_multiplier = 2;
                else
                    tick_multiplier = 1;
                end
            end
            
            tick_spacing = tick_multiplier*(10^power_of_10);
            
            min_value = tick_spacing*(floor(min_value/tick_spacing + 0.1));
            max_value = tick_spacing*(ceil(max_value/tick_spacing - 0.1));
        end
        
    end
end

