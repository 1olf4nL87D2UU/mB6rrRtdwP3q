clc
clear
img=imread('M-010-01.bmp');
img2=imread('M-010-02.bmp');
img3=imread('M-011-01.bmp');

%d=dir('mB6rrRtdwP3q\Data\01');


% Viola-Jones [Per ora lo saltiamo finchè non chiediamo al tutor, è un passaggio inutile date le immagini di input]
%  detector = vision.CascadeObjectDetector('ClassificationModel', 'FrontalFaceLBP') ;
%  
%  bboxes = step(detector,img);
%  
%  IFaces = insertObjectAnnotation(img, 'rectangle', bboxes, 'Face');
%  figure, imshow(IFaces), title('Detected faces');

paramaters = parseXML();

%Funzione copiata da matlab 2015b, ci basta prendere il codice, capirlo e
%commentarlo e abbiamo finito. Prende solo immagini in scala di grigio,
%possibile modifica

%VA ALLEGGERITO managerLBP togliendo le funzioni che gestiscono parametri
%inutili che elimineremo fra questi :
%numNeighbors, radius, interpolation, uniform, upright, cellSize, normalization
features1 = managerLBP.LBPFeaturesExtractor(rgb2gray(img), 8, 1, 'Linear', true, true, round(size(rgb2gray(img))./4), 'L2');
features2 = managerLBP.LBPFeaturesExtractor(rgb2gray(img2), 8, 1, 'Linear', true, true, round(size(rgb2gray(img2))./4), 'L2');
features3 = managerLBP.LBPFeaturesExtractor(rgb2gray(img3), 8, 1, 'Linear', true, true, round(size(rgb2gray(img3))./4), 'L2');


%Distanza tra foto
foto1_1vs1_2=(features1 - features2).^2;
foto1_1vs2_1=(features1 - features3).^2;

%sto solo verificando di non aver fatto errori copiando le varie funzioni
%del toolbox (verifico dopo nella stampa che il valore sia uguale)
f= extractLBPFeatures(rgb2gray(img), 'CellSize', round(size(rgb2gray(img))./4) );
f2= extractLBPFeatures(rgb2gray(img2), 'CellSize', round(size(rgb2gray(img2))./4) );

g=(f-f2).^2;

fprintf('Media distanza tra Foto 1 e 2 dello stesso individuo= %d uguale a= %d\n',mean (foto1_1vs1_2), mean(g) );
fprintf('Media distanza tra le Foto 1 di diversi individui= %d\n',mean (foto1_1vs2_1));


figure
bar([foto1_1vs1_2]', 5, 'grouped')
title('Squared error of LBP Histograms')
xlabel('LBP Histogram Bins')
legend('Foto 1 e 2 Individuo 1')


figure
bar([foto1_1vs2_1 ]', 5,  'grouped')
title('Squared error of LBP Histograms')
xlabel('LBP Histogram Bins')
legend('Foto 1 di diversi individui')

%'I valori del primo grafico sono in generale più bassi di quelli del
%secondo, infatti la media è inferiore..Ciò vuol dire che c'è meno differenza 
