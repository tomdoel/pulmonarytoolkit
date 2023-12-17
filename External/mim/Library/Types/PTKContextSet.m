classdef PTKContextSet
    % PTKContextSet. An enumeration used to specify the regions of interest
    %     over which a plugin can operate
    %
    %     A context set represents a set of contexts. A context is a region
    %     of interest for which the plugin can be executed. Therefore the
    %     context type repesents the set of contexts for which the plugin
    %     can be run.
    %
    %     For example, the "SingleLung" type represents two contexts: "LeftLung"
    %     and "RightLung". A plugin with the "SingleLung" type can only be run
    %     with one of these two input contexts. If a result is requested for
    %     another context, the Framework will try to convert the contexts
    %     appropriately (this happens in the MimContextHierarchy class).
    %
    %     For example, if a result is requested for the conext "LungROI" but the
    %     plugin being called has type "SingleLung", then the plugin will be
    %     called twice (once for "RightLung" and once for "LeftLung"). The
    %     final result will contain both results.
    %
    %     Plugins specify their PTKContextSet by setting their "Context"
    %     class property.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    properties (Constant)
        OriginalImage = 'OriginalImage' % The full image
        LungROI = 'LungROI'             % Region containing the lung and airways
        Lungs = 'Lungs'                 % Left and right lungs
        SingleLung = 'SingleLung'       % Left lung or right lung
        Lobe = 'Lobe'
        Segment = 'Segment'

        Any = 'Any'                     % Valid for any context
    end

end

