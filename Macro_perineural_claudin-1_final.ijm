

run("Bio-Formats Macro Extensions");

directory = getDirectory("Choose a Directory");

fileList = getFileList(directory);

for (file = 0; file < fileList.length; file++) {

	Ext.setId(directory + fileList[file]);
	
	run("Bio-Formats Importer", "open=[" + directory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_3");
	cldn1NerveFibers();
}



function cldn1NerveFibers() {
	run("Options...", "iterations=1 count=1 black do=Nothing");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
	run("ROI Manager...");
	run("Channels Tool...");
	
	image = getTitle();

	selectWindow(image);
	run("Split Channels");

	green = "C1-" + image;
	orange = "C2-"+ image;
	red = "C3-"+ image;

	enhanceContrast(green);
	enhanceContrast(orange);
	enhanceContrast(red);

	run("Merge Channels...", "c1=[" + red + "] c7=[" + orange + "] create keep");
	run("RGB Color");
	run("8-bit");
	selectWindow("Composite");

	run("Merge Channels...", "c1=["+ green + "] c2=[" + red + "] c7=[" + orange + "] create");

    clearROIs();

	waitForUser("Nerve Fibers", "select the nerve fibers");
	combineROIs();

	selectWindow("Composite (RGB)");
	run("Select All");
	waitForUser("Threshold", "run 'Threshold...' and choose a threshold");
	
	roiManager("Select", 0);
	run("Analyze Particles...", "size=3-Infinity clear add");
	combineROIs();
	
	excludeHoles();
	
	selectWindow(image);
	Stack.setActiveChannels("111");
	roiManager("Select", 0);
	waitForUser("Selection", "correct selection");
	
	selectWindow(image);
	Stack.setActiveChannels("111");
	saveAs("png", "E:/Apotome/CLDN1/Nerve Fibers/Images/" + substring(image, 0, lengthOf(image)-4));

	close(image);
	run("Bio-Formats Importer", "open=[E:/Apotome/CLDN1/Nerve Fibers/to be done/"+ substring(image, 0, lengthOf(image)-4) + ".czi] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	run("Split Channels");
	selectWindow("C2-E:/Apotome/CLDN1/Nerve Fibers/to be done/"+ substring(image, 0, lengthOf(image)-4) + ".czi");
	
	waitForUser("Measurement", "measure");

	saveAs("results", "E:/Apotome/CLDN1/Nerve Fibers/Results CLDN1/" + substring(image, 0, lengthOf(image)-4) + ".tsv");
				
	roiManager("Save", "E:/Apotome/CLDN1/Nerve Fibers/ROIs/" + substring(image, 0, lengthOf(image)-4) + ".zip");
	
	run("Close All");
}

function enhanceContrast(channel) { 
	selectWindow(channel);
	run("Enhance Contrast...", "saturated=0.05 normalize");
}

function clearROIs() {
	numberOfRois = RoiManager.size;

	for (n = numberOfRois-1; n > -1; n--) {
		roiManager("Select", n);
		roiManager("delete");
	}
}

function clearROIsButOne() {
	numberOfRois = RoiManager.size;

	for (n = numberOfRois-2; n > -1; n--) {
		roiManager("Select", n);
		roiManager("delete");
	}
}

function combineROIs() {
	selectWindow("ROI Manager");
	roiManager("Deselect")
	roiManager("Combine");
	roiManager("Add");

	clearROIsButOne();
}

function excludeHoles() {
	waitForUser("Threshold", "deselect 'dark background' in 'Threshold...'");

	roiManager("select", 0);
	run("Analyze Particles...", "size=3-Infinity add");
	
	selectWindow("ROI Manager");
	roiManager("Deselect")
	roiManager("XOR");
	roiManager("Add");

	clearROIsButOne();
}