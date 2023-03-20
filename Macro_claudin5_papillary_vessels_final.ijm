
run("Bio-Formats Macro Extensions");

directory = getDirectory("Choose a Directory");


fileList = getFileList(directory);

for (file = 0; file < fileList.length; file++) {
		
	Ext.setId(directory + fileList[file]);
	Ext.getSeriesCount(seriesCount);	

	run("Bio-Formats Importer", "open=[" + directory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	cldn5Intensity();		
}

function cldn5Intensity() {
	run("Options...", "iterations=1 count=1 black do=Nothing");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
	run("ROI Manager...");
	run("Channels Tool...");
	
	image = getTitle();

	selectWindow(image);
	run("Split Channels");

	blue = "C1-" + image;
	green = "C2-"+ image;
	orange = "C3-"+ image;
	red = "C4-"+ image;

	selectWindow(blue);
	run("Enhance Contrast...", "saturated=0.05 normalize");
	selectWindow(green);
	run("Enhance Contrast...", "saturated=0.05 normalize");
	selectWindow(orange);
	run("Enhance Contrast...", "saturated=0.05 normalize");
	selectWindow(red);
	run("Enhance Contrast...", "saturated=0.05 normalize");


	run("Merge Channels...", "c1=[" + green + "] c7=[" + orange + "] create keep");

	run("RGB Color");
	run("8-bit");

	setAutoThreshold("Default dark");

	run("Analyze Particles...", "size=3-Infinity clear add");

	selectWindow("Composite");

	run("Merge Channels...", "c1=[" + blue + "] c2=["+ green + "] c3=[" + orange + "] c7=[" + red + "] create");

	selectWindow("Composite (RGB)");
	roiManager("Show None");
	roiManager("Show All");

	waitForUser("Threshold", "run 'Threshold...' and choose a threshold");

	run("Analyze Particles...", "size=3-Infinity clear add");

	selectWindow("ROI Manager");
	roiManager("Deselect")
	roiManager("Combine");
	roiManager("Add");

	numberOfRois = RoiManager.size;

	for (n = numberOfRois-2; n > -1; n--) {
		roiManager("Select", n);
		roiManager("delete");
	}

	waitForUser("Threshold", "deselect 'dark background' in 'Threshold...'");

	roiManager("select", 0);

	run("Analyze Particles...", "size=3-Infinity add");

	selectWindow("ROI Manager");
	roiManager("Deselect")
	roiManager("XOR");
	roiManager("Add");

	numberOfRois = RoiManager.size;

	for (n = numberOfRois-2; n > -1; n--) {
		roiManager("Select", n);
		roiManager("delete");
	}
	
	selectWindow(image);
	Stack.setActiveChannels("0111");
	roiManager("Select", 0);
	waitForUser("Selection", "correct selection");
	
	
	selectWindow(image);
	Stack.setActiveChannels("1111");
	saveAs("png", "E:/Apotome/CLDN5/Epidermis/Images/" + substring(image, 0, lengthOf(image)-4));

	close(image);
	run("Bio-Formats Importer", "open=[E:/Apotome/CLDN5/Epidermis/to be done/"+ substring(image, 0, lengthOf(image)-4) + ".czi] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	run("Split Channels");
	selectWindow("C2-E:/Apotome/CLDN5/Epidermis/to be done/"+ substring(image, 0, lengthOf(image)-4) + ".czi");
	
	waitForUser("Measurement", "measure");

	saveAs("results", "E:/Apotome/CLDN5/Epidermis/Results CLDN5/" + substring(image, 0, lengthOf(image)-4) + ".tsv");
				
	roiManager("Save", "E:/Apotome/CLDN5/Epidermis/ROIs/" + substring(image, 0, lengthOf(image)-4) + ".zip");
	
	run("Close All");
}
