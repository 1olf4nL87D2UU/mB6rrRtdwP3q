function parameters = parseXML()
%% Caricamento dei parametri di input per l'algoritmo LBP da un file XML

xDoc = xmlread('parameters.xml');
allListitems=xDoc.getElementsByTagName('parameters');
parametersList = allListitems.item(0);

tagElement = parametersList.getElementsByTagName('NumNeighbors');
element = tagElement.item(0);
NumNeighbors=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('Radius');
element = tagElement.item(0);
Radius=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('Upright');
element = tagElement.item(0);
Upright=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('CellSizeDivisior');
element = tagElement.item(0);
CellSizeDivisor=element.getFirstChild.getData;

% Conversione da stringa a bool
if strcmp('true', Upright)
    Upright=true;
else
    Upright=false;
end

parameters= struct('NumNeighbors', str2double(NumNeighbors), 'Radius',  str2double(Radius), 'Upright', Upright, 'CellSizeDivisor', str2double(CellSizeDivisor));
