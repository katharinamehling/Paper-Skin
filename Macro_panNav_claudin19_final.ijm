//Version 14: auto threshold + halbe nodes möglich
  
//setup
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
setOption("BlackBackground", true);
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
run("ROI Manager...");
run("Channels Tool...");

//analysis folders
analysisDir = getDirectory("choose a directory for the analysis folder");

//create Analysis Folders
analysisPath = createFolder("Analysis", analysisDir);
analysisPerPatientPath = createFolder("Analysis per Patient", analysisPath);
analysis3DRoisPath = createFolder("3D Rois", analysisPerPatientPath);
analysisNodeRoisPath = createFolder("Node ROIs", analysisPerPatientPath);
analysisResultsTablesPath = createFolder("Results Tables", analysisPerPatientPath);

//Patient number -> user
Dialog.createNonBlocking("Patient number");
Dialog.addNumber("What number does the patient have?", 1);
Dialog.show();
patientNumber = Dialog.getNumber();

analysis3DRoisPerPatientPath = createFolder("Patient " + patientNumber, analysis3DRoisPath);

//open File
fileName = File.openDialog("Choose a file");

//Bioformats Reader
run("Bio-Formats Macro Extensions");
Ext.setId(fileName);
Ext.getSeriesCount(seriesCount);
			
for (series = 1; series <= seriesCount; series++) {
	//für Results Summary
	totalMeasuredNodes = 0;
	sumVolumePanNav = 0;
	sumIntensityPanNav = 0;
	sumVolumeCldn19= 0;
	sumIntensityCldn19 = 0;
	measuredParanodes = 0;
	
	//clear Roi Manager and close everything
	run("Close All");
	close("Results");
	clearROIs();
	
	run("Bio-Formats Importer", "open=[" + fileName + "] autoscale color_mode=Colorized rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + series);
	 
	originalImage = getTitle();
	
		
	selectWindow(originalImage);
	
	run("Duplicate...", "duplicate"); 
	run("Merge Channels...", "c1=[" + originalImage + "-1] c2=[" + originalImage + "-1] c3=[" + originalImage +  "-1] create");

	selectWindow(originalImage);
	run("Duplicate...", "duplicate");
	 
	//enhanced stacked composite for the selection of a nerve bundel
	selectWindow(originalImage + "-2");
	run("Split Channels");
	
	cldn19 = "C1-" + originalImage + "-2";
	mbp = "C2-" + originalImage + "-2";
	panNav = "C3-" + originalImage + "-2";
	
	prepareChannel(cldn19);
	prepareChannel(mbp);
	prepareChannel(panNav);
	
	run("Merge Channels...", "c1=[AVG_" + cldn19 + "] c2=[AVG_" + mbp + "] c5=[AVG_" + panNav + "] create");

	//Number of Nodes -> user
	Dialog.createNonBlocking("Number of Nodes");
	Dialog.addNumber("How many nodes are in the image?", 1);
	Dialog.show();
	totalNodeNumber = Dialog.getNumber();
	
	if (totalNodeNumber > 0) {			
		//selectNodes 
		selectWindow("Composite");
		roiManager("Show All with labels");
		waitForUser("node selection", "use rectangular selection to select all node");

		//excludeNodes
		selectWindow(originalImage + "-1");
		Stack.setActiveChannels("101");
		roiManager("Show All without labels");
		waitForUser("Node Exclusion","delete ROIs of all nodes, that touch the first or last slice");

		roiCount = roiManager("count");
			
		if (roiCount > 0) {
		
			//saving of the node selections
			roiManager("Save", analysisNodeRoisPath + "Node Selection " + patientNumber + "." + series + ".zip");
			
			for (node = 1; node <= roiCount; node++) {
	
				//prepare Results Table & ROI Manager
				setResult("Node", node-1, "Image" + patientNumber + "." + series + " - Node " + node);
				updateResults();
			
				roiManager("Select", node-1);
				roiManager("Rename", "Node" + node);
			
				//extract node
				selectWindow(originalImage);
				roiManager("Select", node-1);
				run("Duplicate...", "duplicate");
				run("Split Channels");
				close(mbp);
				selectWindow(originalImage);
				roiManager("Select", node-1);
				run("Duplicate...", "duplicate");
				run("Merge Channels...", "c1=[" + originalImage + "-2] c2=[" + originalImage + "-2] c5=[" + originalImage + "-2] create");
				
				run("3D Manager");
			
				//measure PanNav
				choice = "Yes";


				//creation of 3D Node ROIs
				Ext.Manager3D_DeselectAll();
					
				selectWindow(panNav);
				run("Duplicate...", "duplicate");
			
				//binary preparation
				panNavduplicate = panNav + "-1";
	
				selectWindow(panNavduplicate);
				run("Gaussian Blur 3D...", "x=2 y=2 z=2");
				run("Enhance Contrast...", "saturated=0 process_all use");
					
				run("3D Objects Counter", "threshold=30000 objects");
				close(panNavduplicate);
					
				selectWindow("Objects map of " + panNavduplicate);
				Ext.Manager3D_AddImage();
					
				selectWindow(panNav);
				Ext.Manager3D_SelectAll();
						
				waitForUser("Correction", "correct ROIs if necessary");
					
				close("Objects map of " + panNavduplicate);

					
				selectWindow(panNav);
					
				//selection check
				Dialog.createNonBlocking("Selection check");
			  	choices = newArray("Yes", "No");
			  	Dialog.addRadioButtonGroup("Try Objects Counter with other settings?", choices, 2, 1, "No");
			  	Dialog.show;
			  	choice = Dialog.getRadioButton();

				//user chosen threshold
				while (choice == "Yes") {
					Ext.Manager3D_DeselectAll();
					
					selectWindow(panNav);
					run("Duplicate...", "duplicate");
			
					//binary preparation
					panNavduplicate = panNav + "-1";
	
					selectWindow(panNavduplicate);
					run("Gaussian Blur 3D...", "x=2 y=2 z=2");
					run("Enhance Contrast...", "saturated=0 process_all use");
					waitForUser("Adjust Image for 3D Objects Counter");
					
					run("3D Objects Counter");
					close(panNavduplicate);
					
					selectWindow("Objects map of " + panNavduplicate);
					Ext.Manager3D_AddImage();
					
					selectWindow(originalImage + "-2");
					Ext.Manager3D_SelectAll();
						
					waitForUser("Correction", "correct ROIs if necessary");
					
					close("Objects map of " + panNavduplicate);

					
					selectWindow(panNav);
					
					//selection check
					Dialog.createNonBlocking("Selection check");
			  		choices = newArray("Yes", "No");
			  		Dialog.addRadioButtonGroup("Try Objects Counter with other settings?", choices, 2, 1, "No");
			  		Dialog.show;
			  		choice = Dialog.getRadioButton();
				}

				//Rename node ROIs
				Ext.Manager3D_Select(0);
				Ext.Manager3D_Rename("node" + node + " -");

				//measurements: node volume	and intensity
				selectWindow(panNav);
				Ext.Manager3D_Select(0);
				Ext.Manager3D_Measure3D(0,"Vol",volumePanNav);
				setResult("Volume PanNav", node-1, volumePanNav);
				Ext.Manager3D_Quantif3D(0,"Mean",intensityPanNav);
				setResult("Intensity PanNav", node-1, intensityPanNav);	
				updateResults();
					
				close(panNav);
			
				//saving of 3D ROIs
				Ext.Manager3D_DeselectAll();
				Ext.Manager3D_Save(analysis3DRoisPerPatientPath + "3D Roi PanNav " + patientNumber + "." + series + " Node" + node + ".zip");
				Ext.Manager3D_Reset();
				
				totalMeasuredNodes = totalMeasuredNodes + 1;
				sumVolumePanNav = sumVolumePanNav + volumePanNav;
				sumIntensityPanNav = sumIntensityPanNav + intensityPanNav;
					
				run("Select None");
	
				//creation of paranode
				choice = "Yes";

				Ext.Manager3D_DeselectAll();
					
				selectWindow(cldn19);
				run("Duplicate...", "duplicate");
			
				//binary preparation
				cldn19duplicate = cldn19 + "-1";
				selectWindow(cldn19duplicate);
				run("Gaussian Blur 3D...", "x=2 y=2 z=2");
				run("Enhance Contrast...", "saturated=0.1 process_all use");
				
				run("3D Objects Counter", "threshold=28000 objects");
				close(cldn19duplicate);
					
				selectWindow("Objects map of " + cldn19duplicate);
				Ext.Manager3D_AddImage();
					
				selectWindow(originalImage + "-2");
				Ext.Manager3D_SelectAll();

				waitForUser("Correction", "correct ROIs if necessary");
					
				close("Objects map of " + cldn19duplicate);

				selectWindow(cldn19);
					
				//selection check
				Dialog.createNonBlocking("Selection check");
			  	choices = newArray("Yes", "No");
			  	Dialog.addRadioButtonGroup("Try Objects Counter with other settings?", choices, 2, 1, "No");
			  	Dialog.show;
			  	choice = Dialog.getRadioButton();
				
				//creation of 3D Paranode ROIs
				while (choice == "Yes") {
					Ext.Manager3D_DeselectAll();
					
					selectWindow(cldn19);
					run("Duplicate...", "duplicate");
			
					//binary preparation
					cldn19duplicate = cldn19 + "-1";
					selectWindow(cldn19duplicate);
					run("Gaussian Blur 3D...", "x=2 y=2 z=2");
					run("Enhance Contrast...", "saturated=0.1 process_all use");
					waitForUser("Adjust Image for 3D Objects Counter");
				
					run("3D Objects Counter");
					close(cldn19duplicate);
					
					selectWindow("Objects map of " + cldn19duplicate);
					Ext.Manager3D_AddImage();
					
					selectWindow(originalImage + "-2");
					Ext.Manager3D_SelectAll();

					waitForUser("Correction", "correct ROIs if necessary");
					
					close("Objects map of " + cldn19duplicate);

					selectWindow(cldn19);
					
					//selection check
					Dialog.createNonBlocking("Selection check");
			  		choices = newArray("Yes", "No");
			  		Dialog.addRadioButtonGroup("Try Objects Counter with other settings?", choices, 2, 1, "No");
			  		Dialog.show;
			  		choice = Dialog.getRadioButton();
				}
				
				//Rename CLDN19 ROIs + measurements: cldn19 volume + intensity
				Ext.Manager3D_Select(0);
				Ext.Manager3D_Rename("Node " + node + " CLDN19 1" + " -");
								
				selectWindow(cldn19);
				Ext.Manager3D_Select(0);
				Ext.Manager3D_Measure3D(0,"Vol",volume1Cldn19);
				setResult("Volume Cldn19 1", node-1, volume1Cldn19);
				selectWindow(cldn19);
				Ext.Manager3D_Quantif3D(0,"Mean",intensity1Cldn19);
				setResult("Intensity Cldn19 1", node-1, intensity1Cldn19);

				sumVolumeCldn19 = sumVolumeCldn19 + volume1Cldn19;
				sumIntensityCldn19 = sumIntensityCldn19 + intensity1Cldn19;
				measuredParanodes = measuredParanodes + 1;

				Ext.Manager3D_Count(nb_obj);
				
				if (nb_obj >1) {
					Ext.Manager3D_Select(1);
					Ext.Manager3D_Rename("Node " + node + " CLDN19 2" + " -");
					
					Ext.Manager3D_Select(1);
					Ext.Manager3D_Measure3D(1,"Vol",volume2Cldn19);
					setResult("Volume Cldn19 2", node-1, volume2Cldn19);
					selectWindow(cldn19);
					Ext.Manager3D_Quantif3D(1,"Mean",intensity2Cldn19);
					setResult("Intensity Cldn19 2", node-1, intensity2Cldn19);

				 	sumVolumeCldn19 = sumVolumeCldn19 + volume2Cldn19;
				 	sumIntensityCldn19 = sumIntensityCldn19 + intensity2Cldn19;
				 	measuredParanodes = measuredParanodes + 1;
				}

						
				updateResults();
						
				close(cldn19);
		
				//saving of 3D CLDN19 ROIs
				Ext.Manager3D_DeselectAll();
				Ext.Manager3D_Save(analysis3DRoisPerPatientPath + "3D Roi Cldn19 " + patientNumber + "." + series + " Node" + node + ".zip");
				Ext.Manager3D_Reset();
						
				close(originalImage + "-2");
			}

			roiManager("Save", analysisNodeRoisPath + "Node Selection " + patientNumber + "." + series + ".zip");
			saveAs("results", analysisResultsTablesPath + "Results " + patientNumber + "." + series + ".tsv");	
			waitForUser("Results");
			close("Results");
			
			close(originalImage + "-2");
		}
	}
	
	run("Close All");

	//results summary
	setResult("Node", 0, "Image" + patientNumber + "." + series);
	setResult("Measures Nodes", 0, totalMeasuredNodes);
	setResult("Mean Volume PanNav", 0, sumVolumePanNav/totalMeasuredNodes);
	setResult("Mean Intensity PanNav", 0, sumIntensityPanNav/totalMeasuredNodes);
	setResult("Mean Volume Cldn 19", 0, sumVolumeCldn19/measuredParanodes);
	setResult("Mean Intensity Cldn19", 0, sumIntensityCldn19/measuredParanodes);

	updateResults();

	waitForUser("Results Summary");

	saveAs("results", analysisPath + "Results Summary " + patientNumber + "." + series + ".tsv");	
}
	



function createFolder(name, folderDir) {
	folderName = folderDir + name;	
	folderNamePath = folderName + File.separator;
	if (File.exists(folderName)) {
	}else {	
		File.makeDirectory(folderName);
	}
	return folderNamePath;
}

function clearROIs() {
	numberOfRois = RoiManager.size;

	for (n = numberOfRois-1; n > -1; n--) {
		roiManager("Select", n);
		roiManager("delete");
	}
}

function prepareChannel(channel) { 
	selectWindow(channel);
	run("Z Project...", "projection=[Average Intensity]");
	run("Enhance Contrast...", "saturated=0.01");	
	selectWindow(channel);
	run("Close");
}
