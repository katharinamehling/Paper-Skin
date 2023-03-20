//for images <10: substring(image, 0, lengthOf(image)-16)
//for images  =>10: substring(image, 0, lengthOf(image)-17)

run("Options...", "iterations=1 count=1 black do=Nothing");
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
run("ROI Manager...");
run("Channels Tool...");

run("Bio-Formats Macro Extensions");

//run on whole folder
directory = getDirectory("Choose a Directory");
fileList = getFileList(directory);

for (file = 0; file < fileList.length; file++) {

	Ext.setId(directory + fileList[file]);

	//clear Roi Manager and close everything
	run("Close All");
	close("Results");
	clearROIs();
	
	run("Bio-Formats Importer", "open=[" + directory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
	
	dispersionCldn1(file);
}



function dispersionCldn1(file) {

	//prepare image
	image = getTitle();
	run("Split Channels");

	green = "C1-" + image;
	orange = "C2-"+ image;
	red = "C3-"+ image;

	close(green);
	close(red);

	//Lines Analysis of Profiles and Dispersion of CLDN1
	waitForUser("draw 3 lines for profiles");
	roiManager("Save", "E:/Apotome/CLDN1/whole skin/ROIs Profiles CLDN1/" + substring(image, 0, lengthOf(image)-17) + ".zip");

	//Repetitions of Dispersion and Min/Max Analysis	
	for (n = 0; n < 3; n++) {

		//create Profile
		selectWindow(orange);
		roiManager("Select", n);
  		profile = getProfile();
  		Array.print(profile);

		sortedProfile = Array.copy(profile);
		Array.sort(sortedProfile);
		absolutMax = sortedProfile[sortedProfile.length-1];
		print("absolut Maximum: " + absolutMax);
	  	tolerance = absolutMax / 5;
		print("Tolerance: " + tolerance);
	
		choice = "Yes";

		//to be able to try another tolerance 
		while (choice == "Yes") {
			
			mainFunction(n, profile, tolerance, absolutMax);
		
			Dialog.createNonBlocking("Change Tolerance?");
			choices = newArray("Yes", "No");
			Dialog.addRadioButtonGroup("Try different tolerance?", choices, 2, 1, "No");
			Dialog.show;
			choice = Dialog.getRadioButton();

			if (choice == "Yes") {
				Dialog.create("Tolerance");
				Dialog.addSlider("Tolerance: ", 1, 1000, 250);
 				Dialog.show();
 				tolerance = Dialog.getNumber();
			}
		}
	}
}


function clearROIs() {
	numberOfRois = RoiManager.size;

	for (n = numberOfRois-1; n > -1; n--) {
		roiManager("Select", n);
		roiManager("delete");
	}
}

function mainFunction(line, profile, tolerance, absolutMax) { 
	//Plot
  	for (i=0; i<profile.length; i++){
    	setResult("Value", i, profile[i]);
  	}
	Plot.create("Profile", "X", "Value", profile);
	
	//findMaxima -> x Values -> location on line
	maxima = Array.findMaxima(profile, tolerance);
	Array.sort(maxima);
	print("Maxima: ");
	Array.print(maxima);

	//findMinima -> x Values -> location on line
	minima = Array.findMinima(profile, tolerance);
	Array.sort(minima);
	print("Minima: "); 
	Array.print(minima);

	//first Min then Max
	if (maxima.length > minima.length) {
		Array.deleteIndex(maxima, 0);
		print("New Maxima: ");
		Array.print(maxima);
	}
	
	//clear Results Table
	updateResults();
	close("Results");

	//Arrays for y values -> Intensity values
	yArrayMax = newArray(maxima.length);
  	yArrayMin = newArray(minima.length);

  	sumRange = 0;
  	sumRelRange = 0;

	// x and y of Minima and Maxima
	for (i = 1; i < maxima.length ; i++){
		xMax = maxima[i];
		yMax = profile[xMax];
		setResult("Maxima", i-1, yMax);
		yArrayMax[i] = yMax;

		xMin = minima[i];
		yMin = profile[xMin];´
		setResult("Minima", i-1, yMin);
		yArrayMin[i] = yMin;
	}

	print("yArrayMax:");
	Array.print(yArrayMax);
	print("yArrayMin:");
	Array.print(yArrayMin);

	// Results for Range between Max and Min, relative Range: Range normalized to greatest Maximum
	for (i = 1; i < maxima.length; i++) {

		range = yArrayMax[i]-yArrayMin[i];
		setResult("Range", i-1, range);

		relativeRange = range / absolutMax;
		setResult("Relative Range", i-1, relativeRange); 
		
		updateResults();

		//for Means of the MinMax Range and the relative Range
		sumRange = sumRange + range;
		sumRelRange = sumRelRange + relativeRange;
	}

	// Adds Minima and Maxima to Plot
	Plot.setColor("red");
	Plot.setLineWidth(2);
	Plot.add("Maxima", maxima, yArrayMax);

	Plot.setColor("blue");
	Plot.setLineWidth(2);
	Plot.add("Minima", minima, yArrayMin);

	//Main Plot
	Plot.setColor("black");
	Plot.setLineWidth(1);
	Plot.update();
	Plot.setLimits(0.0, NaN, 0, NaN);
	Plot.makeHighResolution("PNG " + n + 1, 4.0);

	//save PNG of Plot and detailed Results
	saveAs("png", "E:/Apotome/CLDN1/whole skin/Profiles CLDN1/" + substring(image, 0, lengthOf(image)-17) + n + 1);
	close("Profile");

	updateResults();
	saveAs("results", "E:/Apotome/CLDN1/whole skin/MinMax Results Profiles CLDN1/" + substring(image, 0, lengthOf(image)-17) + n + 1 + ".tsv");
	close("Results");

	//create and save mean results for one image
	setResult("Image", 0, substring(image, 0, lengthOf(image)-17) + n + 1);
	updateResults();
	
	print("SumRange: " + sumRange);
	print("SumRelRange: " + sumRelRange);
	avRange = sumRange/(maxima.length);
	avRelRange = sumRelRange/(maxima.length);
	print("AvRange: " + avRange);
	print("AvRelRange: " + avRelRange);
	setResult("Mean Range ", 0, avRange);
	setResult("Mean Relative Range ", 0, avRelRange);

	setResult("Maxima", 0, maxima.length);
	selectWindow(orange);
	roiManager("Select", line);
	length = getValue("Length");
	setResult("Length", 0, length);
	setResult("FirstCountedMaximumX", 0, maxima[1]);
	setResult("LastX", 0, profile.length);
	setResult("Tolerance", 0, tolerance);
		
	updateResults();
	
	saveAs("results", "E:/Apotome/CLDN1/whole skin/Results Profiles CLDN1/" + substring(image, 0, lengthOf(image)-17) + n + 1 + ".tsv");
	
	close("Results");
	
}

