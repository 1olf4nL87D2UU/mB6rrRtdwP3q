function distances= getDistances(X, Y)
%%  Calcolo di diversi tipi di distance tra i vettori di features X e Y

%Distanza euclidea
euclideanDistance = pdist2(X,Y,'euclidean');

%Distanza City-Block
minkowski1Distance= pdist2(X,Y,'minkowski',1);

%Media dell'errore quadratico
squaredErrorMean=  mean ((X-Y).^2);

distances= struct ('Euclidean', euclideanDistance, 'CityBlock', minkowski1Distance, 'SquaredErrorMean', squaredErrorMean );