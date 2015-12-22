clc
clear
img=imread('M-010-01.bmp');
img2=imread('M-010-02.bmp');
img3=imread('M-011-01.bmp');

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
features1 = LBPFeaturesExtractor(rgb2gray(img), 'CellSize', round(size(rgb2gray(img))./4)); 
features2 = LBPFeaturesExtractor(rgb2gray(img2),'CellSize', round(size(rgb2gray(img2))./4)); 
features3 = LBPFeaturesExtractor(rgb2gray(img3),'CellSize', round(size(rgb2gray(img3))./4)); 


%Distanza tra foto
foto1_1vs1_2=(features1 - features2).^2;
foto1_1vs2_1=(features1 - features3).^2;


fprintf('Media distanza tra Foto 1 e 2 dello stesso individuo= %d\n',mean (foto1_1vs1_2));
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
