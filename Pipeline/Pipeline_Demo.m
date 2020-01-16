clear; clc; close all;
wkdir = '../'; % The root foler of FM-Bench
addpath([wkdir 'vlfeat-0.9.21/toolbox/']);
vl_setup;

Datasets = {'TUM', 'KITTI', 'Tanks_and_Temples', 'CPC'};

matcher='<methods>'; % SIFT with Ratio Test
estimator='RANSAC';

for s = 1 : length(Datasets)
    rng(0);
    dataset = Datasets{s};
    
    %An example for DoG detector
    %FeatureDetection(wkdir, dataset,true);
    %FeatureExtraction(wkdir,dataset,true);
    %An example for SIFT descriptor
    %PatchExtraction(wkdir,dataset,16);
    %MatchTransform(wkdir,'Corrs',dataset,matcher,false);
    %DataTransform(wkdir, dataset);
    % An example for exhaustive nearest neighbor matching with ratio test
    FeatureMatching(wkdir, dataset, matcher, 'r', 0.8);
    % An example for RANSAC based FM estimation
    GeometryEstimation(wkdir, dataset, matcher, estimator);
end


