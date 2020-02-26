clear; close all; clc;

wkdir = '../';

Datasets = {'TUM', 'KITTI', 'Tanks_and_Temples', 'CPC'};
Methods = {'aslfeat-RANSAC'};
draw_fig = false;

Errors = cell(length(Methods),length(Datasets));
Inlier_rates = cell(length(Methods),length(Datasets));
Numbers = cell(length(Methods),length(Datasets));
for d = 1 : length(Datasets) 
    dataset = Datasets{d};
    for m = 1 : length(Methods)
        method = Methods{m};
        
        results_dir = ['../Results/' dataset '/'];
        filename = [results_dir method '.mat'];
        disp(filename)
        Results = importdata(filename);        
        
        Error = -ones(length(Results), 1);
        Inlier_rate = -ones(length(Results), 2);
        Number =  zeros(length(Results), 2);
        
        for idx = 1 : length(Results)
            if Results{idx}.status ~=0
                Results{idx}.sgd_error = -1;
                Results{idx}.inlier_rate = [0,0];
                continue;
            end
          
            F1 = Results{idx}.F_gt;
            F2 = Results{idx}.F_hat;
            size1 = Results{idx}.size_l;
            size2 = Results{idx}.size_r;
            X1 = Results{idx}.X_l';
            X2 = Results{idx}.X_r';
            inliers = Results{idx}.inliers;

            if isfield(Results{idx}, 'sgd_error') ~= 1 || Results{idx}.sgd_error < 0
                disp(idx)
                Results{idx}.sgd_error = ComputeNormlizedSGD(F1, F2, size1, size2);            
            end
            Error(idx) = Results{idx}.sgd_error; 
            
            if isfield(Results{idx}, 'inlier_rate') ~= 1 || isempty(Results{idx}.inlier_rate) == 1
                Results{idx}.inlier_rate = ComputeInlierRate(F1, X1, X2, inliers, size1, size2, 0.003);     
            end
            Inlier_rate(idx,:) = Results{idx}.inlier_rate;
            Number(idx,:) = [length(Results{idx}.inliers), sum(Results{idx}.inliers)];
        end
        
        save(filename, 'Results');
        
        mask = Error < 0;
        Error(mask) = [];
        Errors{m, d} = Error;
        Inlier_rate(mask,:) = [];
        Inlier_rates{m, d} = Inlier_rate;
        Number(mask, :) = [];
        Numbers{m, d} = Number;        
    end
end


% Recall---(Error)
num_pairs = 1000;
X = linspace(0,0.2,20);
for d = 1 : length(Datasets)
    dataset = Datasets{d};
    Y = zeros(length(Methods), length(X));
    for m = 1 : length(Methods)
       method = Methods{m};
       for t = 1 : length(X)
           Y(m, t) = sum(Errors{m,d} < X(t)) / num_pairs;
       end
    end

    if draw_fig
        figure;
        h = plot(X,Y,'linewidth',3);
        ylim([0 1]);
        legend(h, Methods, 'Location', 'SouthEast');
        title(dataset);
        xlabel('NSGD Threshold');
        ylabel('Recall');
    end
end

threshold = 0.05;
for d = 1 : length(Datasets) 
    dataset = Datasets{d};
    disp(['Dataset : ' dataset]);
    disp('method recall inlier_rate_before inlier_rate_after');
  
    for m = 1 : length(Methods)
       method = Methods{m};
       
       recall = sum(Errors{m,d} < threshold) / num_pairs;

       [meanInlierRate] = mean(Inlier_rates{m,d});
       before_rate = meanInlierRate(1);
       after_rate = meanInlierRate(2);
       
       fprintf(sprintf('%s %f %f %f\n', method, recall, before_rate, after_rate));
    end 
end

for d = 1 : length(Datasets) 
    dataset = Datasets{d};
    for m = 1 : length(Methods)
        method = Methods{m};
        results_dir = [wkdir 'Results/' dataset '/'];
        filename = [results_dir method '.mat'];
        Results = importdata(filename);
        corr_total=0;
        inlier_total=0;
        for idx = 1 : length(Results)
            size1 = Results{idx}.size_l;
            size2 = Results{idx}.size_r;
            X1 = Results{idx}.X_l';
            X2 = Results{idx}.X_r';
            inliers = Results{idx}.inliers;
            corr=size(X1);
            corr_total=corr_total+corr(2);
            inlier_total=inlier_total+sum(inliers);
        end
        avg_corr=corr_total/length(Results);
        avg_inlier=inlier_total/length(Results);
        fprintf('%s: corr:%f  inlier:%f\n',dataset,avg_corr,avg_inlier);
    end
end