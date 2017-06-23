classdef MimParameters < MimStruct
    % MimParameters. Holds parameters that are passed to
    % MimDataset.GetResult()
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        

    methods
        function obj = MimParameters(varargin)
            obj = obj@MimStruct(varargin{:});
        end
    end
end