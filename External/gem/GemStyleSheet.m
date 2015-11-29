classdef GemStyleSheet
    % GemStyleSheet. Defines a stylesheet object used for one GUI component.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        SelectedBackgroundColour = GemDefaultStyleSheet.SelectedBackgroundColour
        TextPrimaryColour = GemDefaultStyleSheet.TextPrimaryColour
        BackgroundColour = GemDefaultStyleSheet.BackgroundColour
        TextSecondaryColour = GemDefaultStyleSheet.TextSecondaryColour
        TextContrastColour = GemDefaultStyleSheet.TextContrastColour
        IconHighlightColour = GemDefaultStyleSheet.IconHighlightColour
        IconSelectedColour = GemDefaultStyleSheet.IconSelectedColour
        IconHighlightSelectedColour = GemDefaultStyleSheet.IconHighlightSelectedColour
        Font = GemDefaultStyleSheet.Font
    end
end