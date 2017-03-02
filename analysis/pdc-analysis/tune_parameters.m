%% tune_parameters

%% tune model order

% tune model order first to get a ballpark model order
% use EWAIC to evaluate
tune_model_order

%% tune gamma and lambda

% tune gamma and lambda with a (hopefully) diminished model order

% use NORMTIME to evaluate
tune_gamma

% use NORMTIME to evaluate
tune_lambda
