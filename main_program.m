function []=PR_system()
    clc;%echo off;close all;%clear all;
    %clear classes all
    close hidden all
    warning off all
    nntraintool('close');

    addpath('include_functions1');
    addpath('include_functions2');

    results_path = 'Results/';
    mkdir(results_path);
    results_file_extension = '.csv'; % (sto linux thelei csv)
    
    imagefiles = {'asymptomatic_roi.bmp', 'symptomatic_ROI.bmp'};
%     imagefile1 = 'asymptomatic_roi.bmp';
%     imagefile2 = 'symptomatic_ROI.bmp';
    
    classifierNames = getClassifierNames();
    featureNames = getTexturalFeatureNames();
    
    %% Extract ROIs and Features
    %  =========================
    [c1_features c2_features] = Program_TexturalFeaturesFromROIs(imagefiles);

    loading_bar = waitbar(0);

    
    %% Save classX.dat
    %  ===============
    % class1
    waitbar(0.2,loading_bar,'Saving Features in class1.dat...');
    for k=1:size(c1_features,1)
        fprintf('\nclass: 1  ROI: %d \n',k);    
        for T=1:size(c1_features,2)
            fprintf('%s:   %f   \n',featureNames{T},c1_features(k,T));   
        end
    end
    save('class1.dat','c1_features','-ascii');
    fprintf('Data SAVED in class1.dat\n');
    
    % class2
    waitbar(0.4,loading_bar,'Saving Features in class2.dat...');
    for k=1:size(c2_features,1)
        fprintf('\nclass: 2  ROI: %d \n',k);    
        for T=1:size(c2_features,2)
            fprintf('%s:   %f   \n',featureNames{T},c2_features(k,T));   
        end
    end
    save('class2.dat','c2_features','-ascii');
    fprintf('Data SAVED in class2.dat\n');

    
    %% Reduce Features (Wilcoxon test)
    %  ===============================
    waitbar(0.6,loading_bar,'Reducing features with Wilcoxn Ranksum...');
    fprintf('\nFeatures Reduced with Wilcoxon rank sum test (0.5 significance level):\n');
    fprintf('----------------------------------------------------------\n');
    ranked_counter = 0;
    P=[];
    for featureN=1:length(featureNames)
        % for every feature on each class test the null hypothesis
        [p, h] = ranksum(c1_features(:,featureN), c2_features(:,featureN));
        if (h==1)
            ranked_counter = ranked_counter + 1;
            fprintf('%d. %s (p=%f)\n',featureN,featureNames{featureN},p);
%         else
%             fprintf('%d. %s (p=%d) <-- NOT SIGNIFICANT\n',feature,featureNames{feature},p);
        end
        P=[P,p];
    end
    fprintf('------------------------\nTotal %d ranked features\n', ranked_counter);
    
    if ranked_counter > 0
        % if ranksum returned results
        % print top ranked features in descending order
        [p,top_ranked]=sort(P);
        top_ranked = top_ranked(1:ranked_counter)
        % select the ranked features for the exhaustive search
        selected_features = top_ranked;
    else
        % else select all features for the exhaustive search
        % as a last resort
        selected_features = 1:featureN;
    end
    
    
    %% Exhaustive Search
    %  =================
    waitbar(0.8,loading_bar,'Creating Feature Vectors (exhaustive search)...');
    features_vectors = {};

    % N = 1/3 * smallest class
    if size(c1_features,1) > size(c1_features,1)
        N = ceil(size(c1_features,1) / 3);
    else
        N = ceil(size(c2_features,1) / 3);
    end
    
    % create all possible feature vectors
    % with each vector's features < N
    for fp=N:-1:1
        features_vector = nchoosek(selected_features,fp);
        for i=1:size(features_vector,1)
            features_vectors{end+1} = features_vector(i,:);
        end
    end
    
    % print vectors
    fprintf('Feature Vectors (Exhaustive, max length %d):', N)
    for i=1:size(features_vectors,2)
        fprintf('\n%d) [',i)
        fprintf('%d ',features_vectors{1,i})  % TODO na to kano me num2str
        fprintf(']')
    end
    fprintf('\n')
    
    delete(loading_bar);

    
    %% Classifiers Selection Menu
    %  ==========================
    [selected_classifiers,ok] = listdlg('PromptString','Select Classifier(s) to evaluate:',...
    'SelectionMode','multiple',...
    'ListSize',[250 350],...
    'ListString',classifierNames);
    selected_classifiers = classifierNames(selected_classifiers);

    if ok == 0
        fprintf('Canceled\n');
        return;
    end

    
    %% Evaluate Classifier (Train, Classify, Save Accuracy and Balance)
    %  ================================================================
    all_in_one_accuracy = [];
    all_in_one_balance = [];
    loading_bar = waitbar(0);
    bar_classifier_counter=0;

    for test_classifier = selected_classifiers'

        excel_data = cell(size(features_vectors,2),6);
        excel_row_names = cell(1,size(features_vectors,2));
        bar_classifier_counter = bar_classifier_counter+1;

        fprintf(['\nEvaluating ' test_classifier{1} '..\n']);
        % for every feature vector
        for i=1:size(features_vectors,2)
            
            fprintf('\n%d. Feature Vector [%s]:\n',...
                i,num2str(features_vectors{i}));
            fprintf(['   Classifier: ' test_classifier{1} '\n']);
            waitbar(i/size(features_vectors,2) * 1/size(selected_classifiers,1) + (bar_classifier_counter-1)/size(selected_classifiers,1),loading_bar,sprintf('Evaluating %s...',strrep(test_classifier{1}, '_', ' ')));

            % set the training data set
            training_c1=c1_features(:,features_vectors{i});
            training_c2=c2_features(:,features_vectors{i});
            
            % ====================================================
            % evaluate classifier's accuracy
            [accuracy, balance, c1_t, c1_f, c2_t, c2_f] = ....
                evaluate_classifier_LOO(test_classifier{1},training_c1,training_c2);
            % ====================================================
            
            % gather results
            excel_data(i,:) = {c1_t c1_f c2_t c2_f accuracy balance};
            excel_row_names(i) = {['[' num2str(features_vectors{i}) ']']};
        end

        % in case there are more than one classifiers selected
        % gather all data in one table
        all_in_one_accuracy = [all_in_one_accuracy, [excel_data(:,end-1)]];
        all_in_one_balance = [all_in_one_balance, [excel_data(:,end)]];

        excel_data = excel_data(:,1:end-1); % remove balance column not to be printed
        % print and save results
        classifier_excel_filename = [results_path test_classifier{1} results_file_extension];
        excel_column_names = {'Class1_T','Class1_F','Class2_T','Class2_F','Overall_Acurracy'};
        Excel_Table = array2table(excel_data, 'VariableNames', excel_column_names, 'RowNames', excel_row_names)
        writetable(Excel_Table,classifier_excel_filename,'WriteRowNames', true);
        fprintf('\nData SAVED to %s\n',classifier_excel_filename);
    end

    delete(loading_bar);

    
    %% Print Results
    %  =============
    message = '';
    % print and save all data
    results_filename = [results_path 'Results' results_file_extension];
    classifierNames(1) = [];
    Results = array2table(all_in_one_accuracy, 'VariableNames', selected_classifiers, 'RowNames', excel_row_names)
    writetable(Results,results_filename,'WriteRowNames', true);
    fprintf('\nData SAVED to %s\n',results_filename);

    % ---- Find the Best Pair -----------
    % the pair with maximum Accuracy
    % rejecting the unBalanced results
    % -----------------------------------
    
    all_in_one_accuracy= cell2mat(all_in_one_accuracy);
    all_in_one_balance=cell2mat(all_in_one_balance);

    % the balance threshold should be the percentage
    % of one misclassified pattern
    if size(c1_features,1) > size(c1_features,1)
        balance_threshold = 100 * 1/size(c1_features,1);
    else
        balance_threshold = 100 * 1/size(c2_features,1);
    end
    % or 5%
    if balance_threshold<5
        balance_threshold=5;
    end

    % remove results below threshold
    all_in_one_accuracy(all_in_one_balance<balance_threshold)=0;
    % find the max
    [a,i]=max(all_in_one_accuracy);
    [a,j]=max(a);
    % print the best
    Best = Results(i(j),j)
    message = {'Best pair:' sprintf('Feature Vector: %s',char(Best.Properties.RowNames)) sprintf('Classifier: %s', char(strrep(Best.Properties.VariableNames, '_', ' ')))};
    waitbar(1, message);
end