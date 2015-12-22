%Temporaneamente incompleto
function parameters = parseXML()

xDoc = xmlread('parameters.xml');
allListitems=xDoc.getElementsByTagName('parameters');
thisListitem = allListitems.item(0);

thisList = thisListitem.getElementsByTagName('NumNeighbors');
p1 = thisList.item(0);
NumNeighbors=p1.getFirstChild.getData;

thisList = thisListitem.getElementsByTagName('Radius');
p2 = thisList.item(0);
Radius=p2.getFirstChild.getData;

thisList = thisListitem.getElementsByTagName('Upright');
p3 = thisList.item(0);
Upright=p3.getFirstChild.getData;

parameters= [NumNeighbors Radius Upright];