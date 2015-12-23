function distances= getDistances(X, Y)

euclideanDistance = pdist2(X,Y,'euclidean');

minkowski1Distance= pdist2(X,Y,'minkowski',1);

squaredErrorMean=  mean ((X-Y).^2);


distances= struct ('Euclidean', euclideanDistance, 'CityBlock', minkowski1Distance, 'SquaredErrorMean', squaredErrorMean );