classdef PTKContextSet
    % PTKContextSet. An enumeration used to specify the regions of interest
    %     over which a plugin can operate 
    %
    %     A context set represents a set of contexts. A context is a ragion
    %     of interest for which the plugin can be executed. Therefore the
    %     context type repesents the set of contexts for which the plugin
    %     can be run.
    %
    %     For example, the "SingleLung" type represents two contexts: "LeftLung"
    %     and "RightLung". A plugin with the "SingleLung" type can only be run
    %     with one of these two input contexts. If a result is requested for
    %     another context, the Framework will try to convert the contexts
    %     appropriately (this happens in the PTKContextHierarchy class).
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    enumeration
        OriginalImage,  % The full image
        LungROI,        % A region containing the lung and airways
        SingleLung      % Left lung or right lung
    end
    
end

