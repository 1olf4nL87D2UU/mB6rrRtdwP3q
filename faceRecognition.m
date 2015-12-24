function featuresVector= faceRecognition(I)
%%  Calcolo del Vettore di Feature di un'Immagine
%   La funzione prende in ingresso un'immagine I, effettua un passo di 
%   detection e ridimensionamento se necessario ed infine utilizza un
%   algoritmo basato su LBP per calcolare il vettore.


%%  Detection tramite Viola-Jones e Ridimensionamento
%   Questo passo viene effettivamente svolto soltanto se il bounding box
%   ottenuto risulta non vuoto, oppure risulta essere pi� piccolo
%   dell'immagine di origini di 0.5 volte. Questo criterio � stato aggiunto per evitare
%   che venga tragliata parte del volto in immagini che sono gi� dei primi piani molto ravvicinati.

detector = vision.CascadeObjectDetector('ClassificationModel', 'FrontalFaceLBP');
bboxes = step(detector,I);
dim= size(I);

%Questo passo di taglio e ridimensionamento � valido nel caso sia stata
%data in input un immagine con un sola persona. Volti multipli non sono
%previsti
if not(isempty(bboxes)) 
    if bboxes(3)<0.5*dim(1) && bboxes(4)<0.5*dim(2)
        
    %Visualizzazione del volto con detection 
    IFaces = insertObjectAnnotation(I, 'rectangle', bboxes, 'Face');
    figure, imshow(IFaces), title('Detected faces');
    
    %Immagine ritagliata in base al bounding box
    croppedI = imcrop(I, bboxes);
    
    
    %Ridimensionamento dell'immagine
    %Dal momento che tutte le immagini del database di test hanno la
    %dimension [165 120], nel caso venissero fornite immagini di dimensioni
    %maggiori anche queste verrano riportate dopo essere stati ritagliati i
    %volti a queste dimensioni, al fine di essere comparabili
    resizedI = imresize(croppedI, [165 120]);
    I=resizedI;
    end
end


%L'algoritmo prende in input immagini in scala di grigio
I=rgb2gray(I);
dim=size(I);

%Recupero parametri statici e calcolo parametri dinamici
paramaters = parseXML();
cellSize=round(dim./paramaters.CellSizeDivisior);



%% Calcolo del feature vectore in base ai parametri forniti tramite file XML
%  Per una migliore comprensione dei parametri visionare i commenti in
%  parameters.xml e managerLBP
featuresVector = managerLBP.LBPFeaturesExtractor(I, paramaters.NumNeighbors, paramaters.Radius, paramaters.Interpolation, paramaters.Uniform,paramaters.Upright, cellSize, paramaters.Normalization);

