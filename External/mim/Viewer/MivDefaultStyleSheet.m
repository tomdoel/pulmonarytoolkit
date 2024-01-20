classdef MivDefaultStyleSheet
    % Defines the default styles for GUI components used by the MIV application
    %
    % When creating a custom application, you may wish to create a new version
    % of this class with appropriate modifications.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Constant)
        SelectedBackgroundColour = [1.0 0.694 0.392]
        TextPrimaryColour = [1.0 1.0 1.0]
        BackgroundColour = [0, 0, 0]
        TextSecondaryColour = [1.0 0.694 0.392]
        TextContrastColour = [0, 0.129, 0.278]
        IconHighlightColour = [0.7 0.7 0.7]
        IconSelectedColour = [0.6 0.6 0]
        IconHighlightSelectedColour = [1 1 0]
        Font = 'Helvetica'
    end
end
