function parameters = parseXML()

xDoc = xmlread('parameters.xml');
allListitems=xDoc.getElementsByTagName('parameters');
parametersList = allListitems.item(0);

tagElement = parametersList.getElementsByTagName('NumNeighbors');
element = tagElement.item(0);
NumNeighbors=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('Radius');
element = tagElement.item(0);
Radius=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('Interpolation');
element = tagElement.item(0);
Interpolation=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('Uniform');
element = tagElement.item(0);
Uniform=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('Upright');
element = tagElement.item(0);
Upright=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('Normalization');
element = tagElement.item(0);
Normalization=element.getFirstChild.getData;

tagElement = parametersList.getElementsByTagName('CellSizeDivisior');
element = tagElement.item(0);
CellSizeDivisior=element.getFirstChild.getData;


if strcmp('true', Uniform)
    Uniform=true;
else
    Uniform=false;
end

if strcmp('true', Upright)
    Upright=true;
else
    Upright=false;
end

parameters= struct('NumNeighbors', str2double(NumNeighbors), 'Radius',  str2double(Radius), 'Interpolation', char(Interpolation), 'Uniform', Uniform, 'Upright', Upright, 'Normalization', char(Normalization), 'CellSizeDivisior', str2double(CellSizeDivisior));
