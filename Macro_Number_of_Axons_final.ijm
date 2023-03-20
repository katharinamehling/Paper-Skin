run("Options...", "iterations=1 count=1 black do=Nothing");
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
run("ROI Manager...");
run("Channels Tool...");

run("Bio-Formats Macro Extensions");

directory = getDirectory("Choose a Directory");

fileList = getFileList(directory);

for (file = 0; file < fileList.length; file++) {

	Ext.setId(directory + fileList[file]);
	
	run("Bio-Formats Importer", "open=[" + directory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_3");
	perineurium(file);
}



function perineurium(file) {

	close("Results");
	
	image = getTitle();

	setResult("Image", 0, substring(image, 0, lengthOf(image)-4));
	
	greenChannel = "C1-" + image;
	orangeChannel = "C2-" + image;
	redChannel = "C3-" + image;
	
	clearROIs();	
	run("Select All");

	if (File.exists("E:/Apotome/CLDN1/Nerve Fibers/ROIs Perineurium/" + substring(image, 0, lengthOf(image)-4) + ".zip")) {

		roiManager("open", "E:/Apotome/CLDN1/Nerve Fibers/ROIs Perineurium/" + substring(image, 0, lengthOf(image)-4) + ".zip");

		run("Split Channels");
	
		selectWindow(greenChannel);
		roiManager("Select", 1);
		run("Find Maxima...", "prominence=100 output=Count");
		run("Find Maxima...", "prominence=100 output=[Point Selection]");
		roiManager("add");
	
		roiManager("Select", 0);
		run("Flatten");
		roiManager("Select", 1);
		run("Flatten");
		roiManager("Select", 2);
		run("Flatten");
		saveAs("png", "E:/Apotome/CLDN1/Nerve Fibers/Images Axon Selection green Channel/" + substring(image, 0, lengthOf(image)-4));	
		run("Merge Channels...", "c1=" + substring(greenChannel, 0, lengthOf(greenChannel)-4) + ".czi c2=" + substring(orangeChannel, 0, lengthOf(orangeChannel)-4) + ".czi c3=" + substring(redChannel, 0, lengthOf(redChannel)-4) + ".czi create");
		
		roiManager("Select", 0);
		run("Flatten");
		roiManager("Select", 1);
		run("Flatten");
		roiManager("Select", 2);
		run("Flatten");
		saveAs("png", "E:/Apotome/CLDN1/Nerve Fibers/Images Axon Selection 3 Channels/" + substring(image, 0, lengthOf(image)-4));
	
		setResult("Image", 0, substring(image, 0, lengthOf(image)-4));
		updateResults();
	
		roiManager("Save", "E:/Apotome/CLDN1/Nerve Fibers/ROIs Axon Count/" + substring(image, 0, lengthOf(image)-4) + ".zip");
	
		saveAs("results", "E:/Apotome/CLDN1/Nerve Fibers/Results Axon Count/" + substring(image, 0, lengthOf(image)-4) + ".tsv");
		close("Results");

	}
	
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