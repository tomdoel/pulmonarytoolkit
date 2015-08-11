classdef PTKStyleSheet
    % PTKStyleSheet. Defines a stylesheet object used for one GUI component.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        SelectedBackgroundColour = PTKDefaultStyleSheet.SelectedBackgroundColour
        TextPrimaryColour = PTKDefaultStyleSheet.TextPrimaryColour
        BackgroundColour = PTKDefaultStyleSheet.BackgroundColour
        TextSecondaryColour = PTKDefaultStyleSheet.TextSecondaryColour
        TextContrastColour = PTKDefaultStyleSheet.TextContrastColour
        IconHighlightColour = PTKDefaultStyleSheet.IconHighlightColour
        IconSelectedColour = PTKDefaultStyleSheet.IconSelectedColour
        IconHighlightSelectedColour = PTKDefaultStyleSheet.IconHighlightSelectedColour
        Font = PTKDefaultStyleSheet.Font
    end
end