%Leave-One-Out Fuction
%
% Returns classification accuracy, balance and the number
% of correctry and false classified patterns.
%
%   Orismata:
%   --------------------------
%   classifier      : string name of classfier
%   class1          : LxF matrix
%   class2          : MxF matrix
%
%   Paradeigma:
%   --------------------------
%   [accuracy, c1_t, c1_f, c2_t, c2_f] = ....
%      evaluate_classifier_LOO('MDC_Classifier',training_set_c1,training_set_c2);

function [accuracy, class1_true, class1_false, class2_true, class2_false] =...
    evaluate_classifier_LOO(classifier,class1,class2)

class1_true = 0;
class1_false = 0;
class2_true = 0;
class2_false = 0;

%classify each pattern in class1 using LOO method
for pattern=1:size(class1,1)
    test_pattern = class1(pattern,:);
    training_c1_loo = class1;
    training_c1_loo(pattern,:) = [];
    [classified]=classify(classifier,test_pattern,training_c1_loo,class2);
    if classified == 1
        class1_true = class1_true + 1;
    else
        class1_false = class1_false + 1;
    end
end
fprintf('    class1 correctly classified %d of %d\n',class1_true,pattern);


%classify each pattern in class2 using LOO method
for pattern=1:size(class2,1)
    test_pattern = class2(pattern,:);
    training_c2_loo = class2;
    training_c2_loo(pattern,:) = [];
    [classified]=classify(classifier,test_pattern,class1,training_c2_loo);
    if classified == 2
        class2_true = class2_true + 1;
    else
        class2_false = class2_false + 1;
    end
end
fprintf('    class2 correctly classified %d of %d\n',class2_true,pattern);

accuracy = (100 * (class1_true+class2_true))/(class1_true+class1_false+class2_true+class2_false);
fprintf('    Overall Accuracy %f\n',accuracy);
end

% ======== END LOO ===================

function [classified] = classify(classifier, unknown_pattern,class1,class2)
    switch classifier
        case 'MDC_Classifier'
            [classified]=MDC_classifier(unknown_pattern,class1,class2);
        case 'Mahanalobis'
            [classified]=maha_classifier(unknown_pattern,class1,class2);
        case 'kNN_k3'
            [classified]=KNN_classifier(unknown_pattern,class1,class2,3);
        case 'kNN_k5'
            [classified]=KNN_classifier(unknown_pattern,class1,class2,5);
        case 'LDA'
            [classified]=LDA_classifier1(unknown_pattern,class1,class2);
        case 'QBayesian'
            [classified]=QBayesian_classifier(unknown_pattern,class1,class2);
        case 'PNN_Gaussian'
            [classified]=PNN_classifier(unknown_pattern,class1,class2,'Gaussian   ');
        case 'PNN_Exponential'
            [classified]=PNN_classifier(unknown_pattern,class1,class2,'Exponential');
        case 'PNN_Reciprocal'
            [classified]=PNN_classifier(unknown_pattern,class1,class2,'Reciprocal ');
        case 'Logistic_Regression'
            [classified]=LogReg_classifier(unknown_pattern,class1,class2);
        case 'Perceptron_separable'
            [classified]=Perceptron_classifier_separable_classes1(unknown_pattern,class1,class2);
        case 'Perceptron_non_separable'
            [classified]=Perceptron_classifier_nonseparable_classes1(unknown_pattern,class1,class2);
        case 'Perceptron_non_separable_Manolis'
            [classified]=perceptron_manolis(unknown_pattern,class1,class2);
        case 'ANN_Matlab_classifier'
            [classified]=ANN_Matlab_classifier1(unknown_pattern,class1,class2);
        case 'SVM_Matlab_classifier'
            [classified]=SVM_Matlab_classifier(unknown_pattern,class1,class2);
        case 'Ensemble_Product_MDC_5NN_QBa'
            [junk,g11,g12]=MDC_classifier(unknown_pattern,class1,class2);
            [junk,g21,g22]=KNN_classifier(unknown_pattern,class1,class2,5);
            [junk,g31,g32]=QBayesian_classifier(unknown_pattern,class1,class2);
            [classified]=ensemble(g11,g12,g21,g22,g31,g32,'Product');
        case 'Ensemble_Sum_MDC_5NN_QBa'
            [junk,g11,g12]=MDC_classifier(unknown_pattern,class1,class2);
            [junk,g21,g22]=KNN_classifier(unknown_pattern,class1,class2,5);
            [junk,g31,g32]=QBayesian_classifier(unknown_pattern,class1,class2);
            [classified]=ensemble(g11,g12,g21,g22,g31,g32,'Sum    ');
        case 'Ensemble_Max_MDC_5NN_QBa'
            [junk,g11,g12]=MDC_classifier(unknown_pattern,class1,class2);
            [junk,g21,g22]=KNN_classifier(unknown_pattern,class1,class2,5);
            [junk,g31,g32]=QBayesian_classifier(unknown_pattern,class1,class2);
            [classified]=ensemble(g11,g12,g21,g22,g31,g32,'Max    ');
        case 'Ensemble_Min_MDC_5NN_QBa'
            [junk,g11,g12]=MDC_classifier(unknown_pattern,class1,class2);
            [junk,g21,g22]=KNN_classifier(unknown_pattern,class1,class2,5);
            [junk,g31,g32]=QBayesian_classifier(unknown_pattern,class1,class2);
            [classified]=ensemble(g11,g12,g21,g22,g31,g32,'Min    ');
    end
end