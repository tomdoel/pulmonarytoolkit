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

        function tick_spacing = GetOptimalTickSpacing(min_value, max_value)
            % Returns the tick spacing required that will look good on printed graphs
            
            range = max_value - min_value;
            
            power_of_10 = log10(range);
            frac = power_of_10 - floor(power_of_10);
            power_of_10 = floor(power_of_10) + (frac > 0.7) - 1;
            tick_spacing = range / 5;
            tick_spacing = (10^power_of_10)*round(tick_spacing/(10^power_of_10)); 
        end
        
    end
end

