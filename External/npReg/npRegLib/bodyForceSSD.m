function [F,S] = bodyForceSSD(A,B,BGrad,U,X,NumRows,NumCols,NumPages,VoxSize,RegDim,HX,HY,HZ);
% bodyForceSSD: compute SSD body force
%
% arguments:
%   A - reference image
%   B - floating image
%   BGrad - gradient of floating image
%   U - displacement field
%   X - field of grid positions
%   NumRows - number of rows in image
%   NumCols - number of columns in image
%   NumPages (optional) - number of pages in (3D) images
%   F - body force field
%   S - value of similarity measure
%
%
%
% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3 licence.
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
%
%

if RegDim == 2 % 2-D

    % evaluate floating image and gradient at deformation grid
    % x and y index are flipped!
    XNew = X-U;

    BWarp = interp2(X(:,:,2),X(:,:,1),B,XNew(:,:,2),XNew(:,:,1),'*linear',0);
    BWarpGrad = cat(3,imfilter(BWarp,HX,'replicate','same'),...
        imfilter(BWarp,HY,'replicate','same'));
    
    % compute difference image
    DiffImage = A - BWarp;

    % compute SSD value
    S = sum(DiffImage(:).^2);

    % finally, compute body force
    F = repmat(DiffImage,[1 1 2]).*BWarpGrad;

else % 3-D
    
    % evaluate floating image and gradient at deformation grid
    % x and y index are flipped!
    XNew = X-U;

    BWarp = interp3(X(:,:,:,2),X(:,:,:,1),X(:,:,:,3),B,XNew(:,:,:,2),XNew(:,:,:,1),XNew(:,:,:,3),'*linear',0);
    BWarpGrad = cat(4,imfilter(BWarp,HX,'replicate','same'),...
        imfilter(BWarp,HY,'replicate','same'),...
        imfilter(BWarp,HZ,'replicate','same'));
    
    % compute difference image
    DiffImage = A - BWarp;

    % compute SSD value
    S = sum(DiffImage(:).^2);

    % finally, compute body force
    F = repmat(DiffImage,[1 1 1 3]).*BWarpGrad;

end