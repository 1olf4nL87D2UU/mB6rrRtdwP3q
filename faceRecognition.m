function featuresVector= faceRecognition(I)

%Per ora si ottengono risultati peggiori con Viola-Jones e
%Ridimensionamento, perciò salto temporaneamente
if false
    detector = vision.CascadeObjectDetector('ClassificationModel', 'FrontalFaceLBP');
    bboxes = step(detector,I);
    
    %If the Viola-Jones Algorithm doesn't detect a Face, we use a bounding box
    %that try to eliminate hairs and chin from the image because they are often not
    %relevant
    if isempty(bboxes)
        dim= size(I);
        bboxes = [5, 5, dim(2)-5, dim(1)-20];
    end
    
    IFaces = insertObjectAnnotation(I, 'rectangle', bboxes, 'Face');
    %figure, imshow(IFaces), title('Detected faces');
    
    croppedI = imcrop(I, bboxes);
    
    
    %RIDIMENSIONAMENTO: va scelto un criterio per determinare la dimensione
    resizedI = imresize(croppedI, [120 100]);
    figure, imshow(resizedI);
    I=resizedI
end

I=rgb2gray(I);

%Recupero parametri statici e calcolo parametri dinamici
paramaters = parseXML();
cellSize=round(size(I)./paramaters.CellSizeDivisior);

%VA ALLEGGERITO managerLBP togliendo le funzioni che gestiscono parametri
%inutili che elimineremo fra questi :
%numNeighbors, radius, interpolation, uniform, upright, cellSize, normalization
featuresVector = managerLBP.LBPFeaturesExtractor(I, paramaters.NumNeighbors, paramaters.Radius, paramaters.Interpolation, paramaters.Uniform,paramaters.Upright, cellSize, paramaters.Normalization);

