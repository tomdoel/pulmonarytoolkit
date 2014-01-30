function name = PTKGetUserVisibleNameForContext(context)
    % PTKGetUserVisibleNameForContext.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    context = char(context);
    
    if strcmp(context, 'Lungs')
        name = 'Both lungs';
    elseif strcmp(context, 'LeftLung')
        name = 'Left lung';
    elseif strcmp(context, 'RightLung')
        name = 'Right lung';
    elseif strcmp(context, 'LeftUpperLobe')
        name = 'Left upper lobe';
    elseif strcmp(context, 'LeftLowerLobe')
        name = 'Left lower lobe';
    elseif strcmp(context, 'RightUpperLobe')
        name = 'Right upper lobe';
    elseif strcmp(context, 'RightLowerLobe')
        name = 'Right lower lobe';
    elseif strcmp(context, 'RightMiddleLobe')
        name = 'Right middle lobe';
    else
        name = context;
    end
end