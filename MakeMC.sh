#!/bin/bash

if [[ $SINGULARITY_NAME != "" ]]; then
	echo "RUNNING IN A SINGULARITY CONTAINER: "$SINGULARITY_NAME
fi

# SET INPUTS
export BATCHRUN=$1
shift
export ENVIRONMENT=$1
shift

if [[ "$BATCHRUN" != "0" ]]; then

xmltest=`echo $ENVIRONMENT | rev | cut -c -4 | rev`
if [[ "$xmltest" == ".xml" ]]; then
source /group/halld/Software/build_scripts/gluex_env_jlab.sh $ENVIRONMENT
else
source $ENVIRONMENT
fi

fi

export ANAENVIRONMENT=$1
shift
export CONFIG_FILE=$1
shift
export OUTDIR=$1
shift
export RUN_NUMBER=$1
shift
export FILE_NUMBER=$1
shift
export EVT_TO_GEN=$1
shift
export VERSION=$1
shift
export CALIBTIME=$1
wholecontext=$VERSION
if [[ "$CALIBTIME" != "notime" ]]; then
wholecontext="variation=$VERSION calibtime=$CALIBTIME"
else
wholecontext="variation=$VERSION"
fi
export JANA_CALIB_CONTEXT="$wholecontext"

shift
export GENR=$1
shift
export GEANT=$1
shift
export SMEAR=$1
shift
export RECON=$1
shift
export CLEANGENR=$1
shift
export CLEANGEANT=$1
shift
export CLEANSMEAR=$1
shift
export CLEANRECON=$1
shift
export BATCHSYS=$1
shift
export NUMTHREADS=$1
shift
export GENERATOR=$1
shift
export GEANTVER=$1
shift
export BKGFOLDSTR=$1
shift
export CUSTOM_GCONTROL=$1
shift
export eBEAM_ENERGY=$1
shift
export COHERENT_PEAK=$1
shift
export GEN_MIN_ENERGY=$1
shift
export GEN_MAX_ENERGY=$1
shift
export TAGSTR=$1
shift
export CUSTOM_PLUGINS=$1
shift
export CUSTOM_ANA_PLUGINS=$1
shift
export PER_FILE=$1
shift
export RUNNING_DIR=$1
shift
export ccdbSQLITEPATH=$1
shift
export rcdbSQLITEPATH=$1
shift
export BGTAGONLY_OPTION=$1
shift
export RADIATOR_THICKNESS=$1
shift
export BGRATE=$1
shift
export RANDBGTAG=$1
shift
export RECON_CALIBTIME=$1
shift
export GEANT_NOSCONDARIES=$1
shift
export MCWRAPPER_VERSION=$1
shift
export NOSIPMSATURATION=$1
shift
export FLUX_TO_GEN=$1
shift
export FLUX_HIST=$1
shift
export POL_TO_GEN=$1
shift
export POL_HIST=$1
shift
export eBEAM_CURRENT=$1
shift
export EXPERIMENT=$1
shift
export RANDOM_TRIG_NUM_EVT=$1
shift
export MCWRAPPER_RUN_LOCATION=$1
shift
export GENERATOR_POST=$1
shift
export GENERATOR_POST_CONFIG=$1
shift
export GENERATOR_POST_CONFIGEVT=$1
shift
export GENERATOR_POST_CONFIGDEC=$1
shift
export GEANT_VERTEXT_AREA=$1
shift
export GEANT_VERTEXT_LENGTH=$1
shift
export MCSMEAR_NOTAG=$1
shift
export PROJECT_DIR_NAME=$1

export USER_BC=`which bc`
export USER_PYTHON=`which python`
export USER_STAT=`which stat`
export BEARER_TOKEN_FILE=${_CONDOR_CREDS}/jlab_gluex.use

length_count=$((`echo $RUN_NUMBER | wc -c` - 1))

formatted_runNumber=""
while [ $length_count -lt 6 ]; do
    formatted_runNumber="0""$formatted_runNumber"
    length_count=$(($length_count + 1))
done

formatted_runNumber=$formatted_runNumber$RUN_NUMBER
flength_count=$((`echo $FILE_NUMBER | wc -c` - 1))

export XRD_RANDOMS_URL=root://sci-xrootd.jlab.org//osgpool/halld/
export RANDOMS_PREPEND=""
if [[ "$BATCHSYS" == "OSG" && "$BATCHRUN"=="1" ]]; then
	export XRD_RANDOMS_URL=xroots://dtn-gluex.jlab.org/
	export RANDOMS_PREPEND="/gluex/mcwrap/"
fi

if [[ ("$MCWRAPPER_RUN_LOCATION" == "JLAB" || `hostname` == *'.jlab.org'*) && "$BATCHSYS" != "slurmcont" ]]; then
	#export XRD_RANDOMS_URL=root://sci-xrootd-ib.qcd.jlab.org//osgpool/halld/
	echo "JLAB DETECTED RESETTING RUNNING DIR"
	echo "changing "$RUNNING_DIR" to ./"
	export RUNNING_DIR="./"
fi

export MAKE_MC_USING_XROOTD=0
#ls /usr/lib64/libXrdPosixPreload.so
if [[ -f /usr/lib64/libXrdPosixPreload.so && "$BKGFOLDSTR" != "None" ]]; then
	export MAKE_MC_USING_XROOTD=1
	export LD_PRELOAD=/usr/lib64/libXrdPosixPreload.so
	echo "XROOTD is available for use if needed..."

	if [[ "$BKGFOLDSTR" == "Random" ]]; then
		#check if xrdfs $XRD_RANDOMS_URL ls /gluex/mcwrap/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm | wc -l returns 1 or an ERROR
		httokendecode -H
		echo "XRD_RANDOMS_URL: $XRD_RANDOMS_URL"
		echo "RANDBGTAG: $RANDBGTAG"
		echo "formatted_runNumber: $formatted_runNumber"

		echo `ls $XRD_RANDOMS_URL/$RANDOMS_PREPEND/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm`
		export con_test=`ls $XRD_RANDOMS_URL/$RANDOMS_PREPEND/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm | head -c 1`

		export contest=`xrdfs $XRD_RANDOMS_URL ls $RANDOMS_PREPEND/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm | wc -l`
		#echo "Executing command: xrdfs $XRD_RANDOMS_URL ls /gluex/mcwrap/random_triggers/$RANDBGTAG/run${formatted_runNumber}_random.hddm | wc -l"
		#xrdfs $XRD_RANDOMS_URL ls /gluex/mcwrap/random_triggers/$RANDBGTAG/run${formatted_runNumber}_random.hddm | wc -l
		#export con_test=$(xrdfs $XRD_RANDOMS_URL ls /gluex/mcwrap/random_triggers/$RANDBGTAG/run${formatted_runNumber}_random.hddm)
		echo "random trigger connection test: $con_test"
		echo xrdfs $XRD_RANDOMS_URL ls $RANDOMS_PREPEND/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm
		echo "random trigger connection test2: $contest"
		if [[ $con_test != "r" && $contest == 0 ]]; then
			echo "JLab Connection test failed. Falling back to UConn...."
			#echo "attempting to copy the needed file from an alternate source..."
			#rsync scosg16.jlab.org:/osgpool/halld/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm ./
			export XRD_RANDOMS_URL=root://nod25.phys.uconn.edu/Gluex/rawdata/
			if [[ `ls $XRD_RANDOMS_URL/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm | head -c 1` != "r" ]]; then
				echo "Cannot connect to the file.  Disabling xrootd...."
				export MAKE_MC_USING_XROOTD=0
			fi
		#else
		#	export XRD_RANDOMS_URL=$XRD_RANDOMS_URL/gluex/mcwrap/
		fi
		
	fi
fi

#override xrootd
#export MAKE_MC_USING_XROOTD=0

if [[ "$BATCHSYS" == "OSG" && "$BATCHRUN"=="1" ]]; then
export USER_BC='/usr/bin/bc'
export USER_STAT='/usr/bin/stat'
fi

#printenv
#necessary to run swif, uses local directory if swif=0 is used
if [[ "$BATCHRUN" != "0" ]]; then
    # ENVIRONMENT
    echo $ENVIRONMENT

    echo pwd=$PWD
    mkdir -p $OUTDIR
    mkdir -p $OUTDIR/log
fi
if [[ "$BATCHSYS" == "QSUB" ]]; then
	if [[ ! -d $RUNNING_DIR ]]; then
		mkdir $RUNNING_DIR
	fi
	cd $RUNNING_DIR
fi



if [[ ! -d $RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER} ]]; then
echo "making work directory "$RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER}
mkdir -p $RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER}
fi
echo "cd $RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER}"
cd $RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER}

if [[ "$ccdbSQLITEPATH" != "no_sqlite" && "$ccdbSQLITEPATH" != "batch_default" && "$ccdbSQLITEPATH" != "jlab_batch_default" ]]; then
	if [[ `$USER_STAT --file-system --format=%T $PWD` == "lustre" ]]; then
		echo "Attempting to use sqlite on a lustre file system. This does not work.  Try running on a different file system!"
		echo "something went wrong with initialization"
		exit 1
	fi
    cp $ccdbSQLITEPATH ./ccdb.sqlite
    export CCDB_CONNECTION=sqlite:///$PWD/ccdb.sqlite

    export JANA_CALIB_URL=$CCDB_CONNECTION
elif [[ "$ccdbSQLITEPATH" == "batch_default" ]]; then
    export CCDB_CONNECTION=sqlite:////group/halld/www/halldweb/html/dist/ccdb.sqlite
    export JANA_CALIB_URL=${CCDB_CONNECTION}
elif [[ "$ccdbSQLITEPATH" == "jlab_batch_default" ]]; then
		#if [[ -f /usr/lib64/libXrdPosixPreload.so ]]; then
		#	xrdcopy $XRD_RANDOMS_URL/ccdb.sqlite ./
		#	export CCDB_CONNECTION=sqlite:///$PWD/ccdb.sqlite

		#else
		#	ccdb_jlab_sqlite_path=`echo $((1 + RANDOM % 100))`
		#	if [[ -f /work/halld/ccdb_sqlite/$ccdb_jlab_sqlite_path/ccdb.sqlite ]]; then
		#		cp /work/halld/ccdb_sqlite/$ccdb_jlab_sqlite_path/ccdb.sqlite $PWD/ccdb.sqlite
		#		export CCDB_CONNECTION=sqlite:///$PWD/ccdb.sqlite
		#		#setenv CCDB_CONNECTION sqlite:////work/halld/ccdb_sqlite/$ccdb_jlab_sqlite_path/ccdb.sqlite
		#	else
		#		export CCDB_CONNECTION=mysql://ccdb_user@hallddb-farm.jlab.org/ccdb
		#	fi
		#fi
	export CCDB_CONNECTION=mysql://ccdb_user@hallddb-farm.jlab.org/ccdb
    export JANA_CALIB_URL=${CCDB_CONNECTION}


fi

#export JANA_GEOMETRY_URL="ccdb:///GEOMETRY/main_HDDS.xml context=\"$VERSION\""


if [[ "$rcdbSQLITEPATH" != "no_sqlite" && "$rcdbSQLITEPATH" != "batch_default" ]]; then
	if [[ `$USER_STAT --file-system --format=%T $PWD` == "lustre" ]]; then
		echo "Attempting to use sqlite on a lustre file system. This does not work.  Try running on a different file system!"
		echo "something went wrong with initialization"
		exit 1
	fi
    cp $rcdbSQLITEPATH ./rcdb.sqlite
    export RCDB_CONNECTION=sqlite:///$PWD/rcdb.sqlite
elif [[ "$rcdbSQLITEPATH" == "batch_default" ]]; then
	#echo "keeping the RCDB on mysql now"
    export RCDB_CONNECTION=sqlite:////group/halld/www/halldweb/html/dist/rcdb.sqlite
fi

echo ""
echo ""
echo "Detected bash shell"

current_files=`find . -maxdepth 1 -type f`

beam_on_current="Not needed"
radthick="Not needed"
colsize="Not Needed"
polarization_angle="Not Needed"
BGRATE_toUse="Not Needed"


gen_pre_rcdb=`echo $GENERATOR | cut -c1-4`
if [[ $gen_pre_rcdb != "file" || "$BGTAGONLY_OPTION" == "1" || "$BKGFOLDSTR" == "BeamPhotons" ]]; then

radthick="50.e-6"

if [[ "$RADIATOR_THICKNESS" != "rcdb" || "$VERSION" != "mc" && "$VERSION" != "mc_workfest2018" && "$VERSION" != "mc_cpp" && "$VERSION" != "mc_JEF" ]]; then
	radthick=$RADIATOR_THICKNESS
else
	words=`rcnd $RUN_NUMBER radiator_type | sed 's/ / /g' `
	for word in $words;
	do
		if [[ "$word" != "number" ]]; then
			if [[ "$word" == "3x10-4" ]]; then
				radthick="30e-6"
				break
			else
				removedum=`echo $word | sed 's/um/ /g'`
				if [[ $removedum != $word ]]; then
					radthick=`echo "$removedum e-6" | tr -d '[:space:]'`
				fi
			fi
		fi
	done
fi
echo "Radiator thickness set..."
polarization_angle=`rcnd $RUN_NUMBER polarization_angle | awk '{print $1}'`


if [[ "$polarization_angle" == "" ]]; then
	poldir=`rcnd $RUN_NUMBER polarization_direction | awk '{print $1}'`

	if [[ "$poldir" == "PARA" ]]; then
		polarization_angle="0.0"
	elif [[ "$poldir" == "PERP" ]]; then
		polarization_angle="90.0"
	else
		polarization_angle="-1.0"
	fi
fi

echo "Polarization angle set..."

elecE=0

variation=$VERSION
if [[ $CALIBTIME != "notime" ]]; then
	variation=$variation":"$CALIBTIME
fi


ccdbelece="`ccdb dump PHOTON_BEAM/endpoint_energy:${RUN_NUMBER}:${variation} | grep -v \#`"

#ccdblist=(`echo ${ccdbelece}`) #(${ccdbelece:/\ /\ /})
#ccdblist_length=${#ccdblist[@]}
elecE_text="$ccdbelece" #`echo ${ccdblist[$(($ccdblist_length-1))]}`
#elecE_text=`rcnd $RUN_NUMBER beam_energy | awk '{print $1}'`

if [[ "$eBEAM_ENERGY" != "rcdb" || "$VERSION" != "mc" && "$VERSION" != "mc_workfest2018" && "$VERSION" != "mc_cpp" && "$VERSION" != "mc_JEF" ]]; then
    elecE=$eBEAM_ENERGY
elif [[ $elecE_text == "Run" ]]; then
	elecE=12
elif [[ $elecE_text == "-1.0" ]]; then
	elecE=12 #Should never happen
else
	elecE=`echo $elecE_text`
	#elecE=`echo "$elecE_text / 1000" | bc -l `
fi

echo "Electron beam energy set..."

copeak=0
copeak_text=`rcnd $RUN_NUMBER coherent_peak | awk '{print $1}'`

if [[ "$COHERENT_PEAK" != "rcdb" && "$polarization_angle" == "-1.0" ]]; then
copeak=$COHERENT_PEAK
else
	if [[ "$COHERENT_PEAK" != "rcdb" || "$VERSION" != "mc" && "$VERSION" != "mc_workfest2018" && "$VERSION" != "mc_cpp" && "$VERSION" != "mc_JEF" ]]; then
    	copeak=$COHERENT_PEAK
	elif [[ $copeak_text == "Run" ]]; then
		copeak=9
	elif [[ $copeak_text == "-1.0" ]]; then
		copeak=0
	else
		copeak=`echo "$copeak_text / 1000" | $USER_BC -l `
	fi
fi

if [[ "$polarization_angle" == "-1.0" && "$COHERENT_PEAK" == "rcdb" ]]; then
	copeak=0
fi
#echo $copeak

#set copeak=`rcnd $RUN_NUMBER coherent_peak | awk '{print $1}' | sed 's/\.//g' #| awk -vFS="" -vOFS="" '{$1=$1"."}1' `

export COHERENT_PEAK=$copeak
echo "Coherent peak set..."

if [[ "$VERSION" != "mc" && "$VERSION" != "mc_cpp" && "$VERSION" != "mc_JEF" && "$VERSION" != "mc_workfest2018" && "$COHERENT_PEAK" == "rcdb" ]]; then
	echo "error in requesting rcdb for the coherent peak while not using variation=mc"
	echo "something went wrong with initialization"
	exit 1
fi

export eBEAM_ENERGY=$elecE
echo "eBEAM energy set..."

if [[ "$VERSION" != "mc" && "$VERSION" != "mc_cpp" && "$VERSION" != "mc_JEF" && "$VERSION" != "mc_workfest2018" && "$eBEAM_ENERGY" == "rcdb" ]]; then
	echo "error in requesting rcdb for the electron beam energy and not using variation=mc"
	echo "something went wrong with initialization"
	exit 1
fi

echo RCDB exe: `which rcnd`

if [[ "$eBEAM_CURRENT" == "rcdb" ]]; then
beam_on_current=`rcnd $RUN_NUMBER beam_on_current | awk '{print $1}'`
echo beam_on_current is $beam_on_current


if [[ $beam_on_current == "" || $beam_on_current == "Run" ]]; then
echo "Run $RUN_NUMBER does not have a beam_on_current.  Defaulting to beam_current."
beam_on_current=`rcnd $RUN_NUMBER beam_current | awk '{print $1}'`
echo beam_current is `rcnd $RUN_NUMBER beam_current`
fi
	if [[ $beam_on_current == "Run" ]]; then
		echo "The beam current could not be found for Run "$RUN_NUMBER".  This is most like due to the run number provided not existing in the rcdb"
		echo "Please set eBEAM_CURRENT explicitly in MC.config..."
		echo "something went wrong with initialization"
		exit 1
	fi

	beam_on_current=`echo "$beam_on_current / 1000." | $USER_BC -l`
	echo "$eBEAM_CURRENT"
else
	beam_on_current=$eBEAM_CURRENT
fi
echo "beam (on) current set..."

colsize=`rcnd $RUN_NUMBER collimator_diameter | awk '{print $1}' | sed -r 's/.{2}$//' | sed -e 's/\.//g'`
if [[ "$colsize" == "B" || "$colsize" == "R" || "$JANA_CALIB_CONTEXT" != "variation=mc" ]]; then
    colsize="50"
fi
echo "Collimator size set..."

BGRATE_toUse=$BGRATE

if [[ "$BGRATE" != "rcdb" || "$VERSION" != "mc" && "$VERSION" != "mc_workfest2018" && "$VERSION" != "mc_cpp" && "$VERSION" != "mc_JEF" ]]; then
    BGRATE_toUse=$BGRATE
else
	if [[ $BGTAGONLY_OPTION == "1" || $BKGFOLDSTR == "BeamPhotons" ]]; then
		echo "Calculating BGRate.  This process takes a minute..."
		BGRATE_toUse=`BGRate_calc --runNo $RUN_NUMBER --coherent_peak $COHERENT_PEAK --beam_on_current $beam_on_current --beam_energy $eBEAM_ENERGY --collimator_diameter 0.00$colsize --radiator_thickness $radthick --endpoint_energy_low $GEN_MIN_ENERGY --endpoint_energy_high $GEN_MAX_ENERGY`

		if [[ $BGRATE_toUse == "" ]]; then
			echo "BGrate_calc is not built or inaccessible.  Please check your build and/or specify a BGRate to be used."
			echo "something went wrong with initialization"
			exit 12
		else
			BGRATE_list=(`echo ${BGRATE_toUse}`)
			BGRATE_list_length=${#BGRATE_list[@]}
			BGRATE_toUse=`echo ${BGRATE_list[$(($BGRATE_list_length-1))]}`
		fi
	fi

fi

if [[ "$polarization_angle" == "-1.0" ]]; then
		POL_TO_GEN=0
fi
fi

isGreater=1
#echo $isGreater
isGreater=`echo $GEN_MAX_ENERGY'>'$eBEAM_ENERGY | $USER_BC -l`
#echo $isGreater
#echo "$isGreater"
if [[ "$isGreater" == "1" && "$eBEAM_ENERGY" != "rcdb" ]]; then
echo "WARNING: User requested GEN_MAX_ENERGY > eBEAM_ENERGY.  This is not possible.  Setting GEN_MAX_ENERGY to eBEAM_ENERGY..."
export GEN_MAX_ENERGY=$eBEAM_ENERGY
fi

# PRINT INPUTS
echo "Using : " $BATCHSYS
echo "This job has been configured to run at: " $MCWRAPPER_RUN_LOCATION" : "`hostname`
echo "Job started: " `date`
echo "Simulating the Experiment: " $EXPERIMENT
echo "ccdbsqlite path: " $ccdbSQLITEPATH $CCDB_CONNECTION
echo "rcdbsqlite path: " $rcdbSQLITEPATH $RCDB_CONNECTION
echo "Producing file number: "$FILE_NUMBER
echo "Containing: " $EVT_TO_GEN"/""$PER_FILE"" events"
echo "Running location:" $RUNNING_DIR
echo "Current Working Directory:" $PWD
echo "Output location: "$OUTDIR
echo "Project directory name: "$PROJECT_DIR_NAME
echo "Environment file: " $ENVIRONMENT
echo "Analysis Environment file: " $ANAENVIRONMENT
echo "Context: "$JANA_CALIB_CONTEXT
echo "Geometry URL: "$JANA_GEOMETRY_URL
echo "Reconstruction calibtime: "$RECON_CALIBTIME
echo "Run Number: "$RUN_NUMBER
echo "Electron beam current to use: "$beam_on_current" uA"
echo "Electron beam energy to use: "$eBEAM_ENERGY" GeV"
echo "Radiator Thickness to use: "$radthick" m"
echo "Collimator Diameter: 0.00"$colsize" m"
echo "Photon Energy between "$GEN_MIN_ENERGY" and "$GEN_MAX_ENERGY" GeV"
echo "Polarization Angle: "$polarization_angle "degrees"
echo "Coherent Peak position: "$COHERENT_PEAK
echo "----------------------------------------------"
echo "Run generation step? "$GENR"  Will be cleaned?" $CLEANGENR
echo "Flux Hist to use: " "$FLUX_TO_GEN" " : " "$FLUX_HIST"
echo "Polarization to use: " "$POL_TO_GEN" " : " "$POL_HIST"
echo "Using "$GENERATOR" with config: "$CONFIG_FILE
echo "Will run "$GENERATOR_POST" postprocessing after generator with configuration: "$GENERATOR_POST_CONFIG", event definitions: "$GENERATOR_POST_CONFIGEVT" and decay definitions: "$GENERATOR_POST_CONFIGDEC
echo "----------------------------------------------"
echo "Run geant step? "$GEANT"  Will be cleaned?" $CLEANGEANT
echo "Using geant"$GEANTVER
echo "Custom Gcontrol?" "$CUSTOM_GCONTROL"
echo "Background to use: "$BKGFOLDSTR
echo "Random trigger background to use: "$RANDBGTAG
echo "BGRATE will be set to: "$BGRATE_toUse" GHz (if applicable)"
echo "Run mcsmear? "$SMEAR"  Will be cleaned?" $CLEANSMEAR
echo "----------------------------------------------"
echo "Run reconstruction? "$RECON"  Will be cleaned?" $CLEANRECON
echo "With additional plugins: "$CUSTOM_PLUGINS
echo "With additional analysis launch plugins: "$CUSTOM_ANA_PLUGINS
echo "=============================================="
echo ""
echo ""
echo "=======SOFTWARE USED======="
echo "MCwrapper version v"$MCWRAPPER_VERSION
echo "MCwrapper location" $MCWRAPPER_CENTRAL
echo "LDPRELOAD: " $LD_PRELOAD
echo "Streaming via xrootd? "$MAKE_MC_USING_XROOTD "Event Count: "$RANDOM_TRIG_NUM_EVT
echo "BC "$USER_BC
echo "python "$USER_PYTHON
echo `which $GENERATOR`
if [[ "$GENERATOR_POST" != "No" ]]; then
echo `which $GENERATOR_POST`
fi

if [[ "$GEANTVER" == "3" ]]; then
	echo `which hdgeant`
else
	echo `which hdgeant4`
fi
echo `which mcsmear`
echo `which hd_root`
echo ""
echo ""



if [[ "$CUSTOM_GCONTROL" == "0" && "$GEANT" == "1" ]]; then
	if [[ "$EXPERIMENT" == "GlueX" ]]; then
		 cp $MCWRAPPER_CENTRAL/Gcontrol.in ./temp_Gcontrol.in
	elif [[ "$EXPERIMENT" == "CPP" ]]; then
		cp $MCWRAPPER_CENTRAL/Gcontrol_cpp.in ./temp_Gcontrol.in
	else
		cp $MCWRAPPER_CENTRAL/Gcontrol.in ./temp_Gcontrol.in
	fi

    chmod 777 ./temp_Gcontrol.in
elif [[ "$CUSTOM_GCONTROL" != "0" && "$GEANT" == "1" ]]; then
    cp $CUSTOM_GCONTROL ./temp_Gcontrol.in
else
	echo "NO GEANT"
fi


formatted_fileNumber=""
while [ $flength_count -lt 3 ]; do
    formatted_fileNumber="0""$formatted_fileNumber"
    flength_count=$(($flength_count + 1))
done

formatted_fileNumber=$formatted_fileNumber$FILE_NUMBER

custom_tag=""

if [[ "$TAGSTR" != "I_dont_have_one" ]]; then
    custom_tag=$TAGSTR\_
fi

STANDARD_NAME=$custom_tag$formatted_runNumber\_$formatted_fileNumber

if [[ `echo $eBEAM_ENERGY | grep -o "\." | wc -l` == 0 ]]; then
    eBEAM_ENERGY=$eBEAM_ENERGY\.
fi
if [[ `echo $COHERENT_PEAK | grep -o "\." | wc -l` == 0 ]]; then
    COHERENT_PEAK=$COHERENT_PEAK\.
fi
if [[ `echo $GEN_MIN_ENERGY | grep -o "\." | wc -l` == 0 ]]; then
    GEN_MIN_ENERGY=$GEN_MIN_ENERGY\.
fi
if [[ `echo $GEN_MAX_ENERGY | grep -o "\." | wc -l` == 0 ]]; then
    GEN_MAX_ENERGY=$GEN_MAX_ENERGY\.
fi

if [[ ! -d "$OUTDIR" ]]; then
    mkdir $OUTDIR
fi
if [[ ! -d "$OUTDIR/configurations/" ]]; then
    mkdir $OUTDIR/configurations/
fi
if [[ ! -d "$OUTDIR/configurations/generation/" ]]; then
    mkdir $OUTDIR/configurations/generation/
fi
if [[ ! -d "$OUTDIR/configurations/geant/" ]]; then
    mkdir $OUTDIR/configurations/geant/
fi
if [[ ! -d "$OUTDIR/hddm/" ]]; then
    mkdir $OUTDIR/hddm/
fi
if [[ ! -d "$OUTDIR/root/" ]]; then
    mkdir $OUTDIR/root/
fi


bkglocstring=""
bkgloc_pre=`echo $BKGFOLDSTR | cut -c 1-4`
if [[ "$BKGFOLDSTR" == "DEFAULT" || "$bkgloc_pre" == "loc:" || "$BKGFOLDSTR" == "Random" ]]; then
		    #find file and run:1

			if [[ "$RANDBGTAG" == "none" && "$bkgloc_pre" != "loc:" ]]; then
				echo "Random background requested but no tag given. Please provide the desired tag e.g Random:recon-2017_01-ver03"
				echo "something went wrong with initialization"
				exit 1
			fi
		    echo "Finding the right file to fold in during MCsmear step"

			runperiod="RunPeriod-2017-01"

		    if [[ $RUN_NUMBER -gt 40000 || $RUN_NUMBER == 40000 ]]; then
				runperiod="RunPeriod-2018-01"
			elif [[ $RUN_NUMBER -gt 30000 || $RUN_NUMBER == 30000 ]]; then
				runperiod="RunPeriod-2017-01"
			elif [[ $RUN_NUMBER -gt 20000 || $RUN_NUMBER == 20000 ]]; then
				runperiod="RunPeriod-2016-10"
			elif [[ $RUN_NUMBER -gt 10000 || $RUN_NUMBER == 10000 ]]; then
				runperiod="RunPeriod-2016-02"
		    fi

		    if [[ $RUN_NUMBER < 10000 ]]; then
			echo "Warning: random triggers do not exist for this run number"
			exit
		    fi

			if [[ "$bkgloc_pre" == "loc:" ]]; then
			rand_bkg_loc=`echo $BKGFOLDSTR | cut -c 5-`
 		   		if [[ "$BATCHSYS" == "OSG" && $BATCHRUN != 0 ]]; then
				    if [[ "$MAKE_MC_USING_XROOTD" == "0" ]]; then
						bkglocstring="/srv""/run$formatted_runNumber""_random.hddm"
				    else
						bkglocstring="$XRD_RANDOMS_URL/random_triggers/$RANDBGTAG/run$formatted_runNumber""_random.hddm"
				    fi
				else
			    	bkglocstring=$rand_bkg_loc"/run$formatted_runNumber""_random.hddm"
			    fi
			else
		    #bkglocstring="/cache/halld/""$runperiod""/sim/random_triggers/""run$formatted_runNumber""_random.hddm"
			    if [[ "$BATCHSYS" == "OSG" && $BATCHRUN != 0 ]]; then
				if [[ "$MAKE_MC_USING_XROOTD" == "0" ]]; then
					bkglocstring="/srv""/run$formatted_runNumber""_random.hddm"
				    else
					bkglocstring="$XRD_RANDOMS_URL/random_triggers/$RANDBGTAG/run$formatted_runNumber""_random.hddm"
				    fi
				else
		    		bkglocstring="/work/osgpool/halld/random_triggers/"$RANDBGTAG"/run"$formatted_runNumber"_random.hddm"
					if [[ `hostname` == 'scosg16.jlab.org' || `hostname` == 'scosg20.jlab.org' || `hostname` == 'scosg2201.jlab.org' ]]; then
						bkglocstring="/work/osgpool/halld/random_triggers/"$RANDBGTAG"/run"$formatted_runNumber"_random.hddm"
					fi
				fi
			fi
			#set bkglocstring="/w/halld-scifs1a/home/tbritton/converted.hddm"

		    if [[ ! -f $bkglocstring && "$MAKE_MC_USING_XROOTD" == "0" ]]; then
			echo "something went wrong with initialization"
			echo "Could not find mix-in file "$bkglocstring
			exit 1000
		    fi

			#if [[ "$BATCHSYS" == "OSG" && "$MAKE_MC_USING_XROOTD" == "1" && $RANDOM_TRIG_NUM_EVT == -1 ]]; then
			#echo "something went wrong with initialization"
			#echo "Could not find mix-in file "$bkglocstring
			#exit 1000
		    #fi
fi


recon_pre=`echo $CUSTOM_PLUGINS | cut -c1-4`
jana_config_file=`echo $CUSTOM_PLUGINS | sed -r 's/^.{5}//'`
echo "RECO PREFIX:  " $recon_pre
if [[ $recon_pre == "file" ]]; then
	if [[ -f $jana_config_file ]]; then
	echo "gathering jana config file"
	cp $jana_config_file ./jana_config.cfg
	fi
fi
gen_pre=""

if [[ "$CUSTOM_ANA_PLUGINS" != "None" ]]; then
	ana_pre=`echo $CUSTOM_ANA_PLUGINS | cut -c1-4`
	jana_ana_config_file=`echo $CUSTOM_ANA_PLUGINS | sed -r 's/^.{5}//'`
	echo "ANA PREFIX:  " $ana_pre
	if [[ $ana_pre == "file" ]]; then
		if [[ -f $jana_ana_config_file ]]; then
		echo "gathering jana config file"
		cp $jana_ana_config_file ./ana_jana.cfg
		fi
	fi
fi


if [[ "$GENR" != "0" ]]; then

	gen_pre=`echo $GENERATOR | cut -c1-4`

    if [[ "$gen_pre" != "file" && "$GENERATOR" != "genr8" && "$GENERATOR" != "bggen" && "$GENERATOR" != "genEtaRegge" && "$GENERATOR" != "genScalarRegge" && "$GENERATOR" != "gen_2pi_amp" && "$GENERATOR" != "gen_pi0" && "$GENERATOR" != "gen_2pi_primakoff" && "$GENERATOR" != "gen_2pi0_primakoff" && "$GENERATOR" != "gen_omega_3pi" && "$GENERATOR" != "gen_omegapi" && "$GENERATOR" != "gen_2k" && "$GENERATOR" != "bggen_jpsi" && "$GENERATOR" != "gen_ee" && "$GENERATOR" != "gen_ee_hb" && "$GENERATOR" != "particle_gun" && "$GENERATOR" != "geantBEAM" && "$GENERATOR" != "bggen_phi_ee" && "$GENERATOR" != "genBH" && "$GENERATOR" != "gen_omega_radiative" && "$GENERATOR" != "gen_amp" && "$GENERATOR" != "gen_amp_V2" && "$GENERATOR" != "genr8_new" && "$GENERATOR" != "gen_compton" && "$GENERATOR" != "gen_npi" && "$GENERATOR" != "gen_compton_simple" && "$GENERATOR" != "gen_primex_eta_he4" && "$GENERATOR" != "gen_whizard" && "$GENERATOR" != "mc_gen" && "$GENERATOR" != "gen_vec_ps" && "$GENERATOR" != "bggen_upd" && "$GENERATOR" != "python"  && "$GENERATOR" != "gen_gcf" && "$GENERATOR" != "gen_ALP" && "$GENERATOR" != "gen_MF" && "$GENERATOR" != "genA" && "$GENERATOR" != "gen_jpsi_hc" && "$GENERATOR" != "gen_coherent"]]; then
		echo "NO VALID GENERATOR GIVEN"
		echo "only [genr8, bggen, genEtaRegge, genScalarRegge, gen_2pi_amp, gen_pi0, gen_omega_3pi, gen_2k, bggen_jpsi, gen_ee, gen_ee_hb,  bggen_phi_ee, particle_gun, geantBEAM, genBH, gen_omega_radiative, gen_amp, gen_amp_V2, gen_compton, gen_npi, gen_compton_simple, gen_primex_eta_he4, gen_whizard, gen_omegapi, mc_gen, gen_vec_ps, bggen_upd, python, gen_gcf, gen_ALP, gen_MF, genA, gen_jpsi_hc, gen_coherent] are supported"
		exit 1
    fi

	if [[ "$gen_pre" == "file" ]]; then
		gen_in_file=`echo $GENERATOR | sed -r 's/^.{5}//'`
		echo "bypassing generation"
		echo "using "$gen_in_file

		if [[ -f $gen_in_file ]]; then
			echo "using pre-generated file: "$gen_in_file
			cp $gen_in_file ./$STANDARD_NAME.hddm
		else
			echo "cannot find file: "$gen_in_file
			exit
		fi
			generator_return_code=0

	elif [[ "$GENERATOR" == "particle_gun" ]]; then
		echo "bypassing generation"
		echo "using" $CONFIG_FILE
		if [[ "$CUSTOM_GCONTROL" == "0" ]]; then
			if [[ ! -f $CONFIG_FILE ]]; then
				echo "Generator config file : "$CONFIG_FILE "not found"
				echo "something went wrong with initialization"
				exit 1
			else
				echo "performing error checking"
				echo "Note: this specific error checking has been disabled as it causes issues on some bash shells.  Basically if you need to use the THETA and PHI parameters then make sure they are set."
				#echo `grep "^[^c]" | grep KINE $CONFIG_FILE | awk '{print $2}' `
				#echo `grep "^[^c]" | grep KINE $CONFIG_FILE | wc -w`
				#if [[ `grep "^[^c]" | grep KINE $CONFIG_FILE | awk '{print $2}' ` < 100 && `grep "^[^c]" | grep KINE $CONFIG_FILE | wc -w` > 3 ]]; then
				#	echo "ERROR THETA AND PHI APPEAR TO BE SET BUT WILL BE IGNORED.  PLEASE REMOVE THESE SETTINGS FROM:"$CONFIG_FILE" AND RESUBMIT."
				#	exit 1
				#elif [[ `grep "^[^c]" | grep KINE $CONFIG_FILE | awk '{print $2}' ` > 100 && `grep "^[^c]" | grep KINE $CONFIG_FILE | wc -w` < 8 ]]; then
				#	echo "ERROR THETA AND PHI DON'T APPEAR TO BE SET BUT ARE GOING TO BE USED. PLEASE ADD THESE SETTINGS FROM: "$CONFIG_FILE" AND RESUBMIT."
				#	exit 1
				#fi
			fi
		fi
    generator_return_code=0
  elif [[ "$GENERATOR" == "geantBEAM" ]]; then
		echo "bypassing generation"
		echo "using" $CONFIG_FILE
		if [[ "$CUSTOM_GCONTROL" == "0" ]]; then
			if [[ ! -f $CONFIG_FILE ]]; then
				echo "Generator config file : "$CONFIG_FILE "not found"
				echo "something went wrong with initialization"
				exit 1
			else
				echo "performing error checking"
				echo "Note: this specific error checking has been disabled as it causes issues on some bash shells.  Basically if you use the GENBEAM parameters then make sure they are set correctly."
				# echo `grep "^[^c]" | grep GENBEAM $CONFIG_FILE | awk '{print $2}' `
				# if [[ `grep "^[^c]" | grep GENBEAM $CONFIG_FILE | awk '{print $2}' ` != "'precol'" && `grep "^[^c]" | grep GENBEAM $CONFIG_FILE | awk '{print $2}' ` != "'postcol'" && `grep "^[^c]" | grep GENBEAM $CONFIG_FILE | awk '{print $2}' ` != "'postconv'" && `grep "^[^c]" | grep GENBEAM $CONFIG_FILE | awk '{print $2}' ` != "'BHgen'"  ]]; then
				# 	echo "ERROR GENBEAM CARD NOT VALID.  PLEASE CHANGE THE SETTING IN:"$CONFIG_FILE" AND RESUBMIT."
				# 	exit 1
				# fi
			fi
		fi

		generator_return_code=0
	else
		if [[ -f $CONFIG_FILE ]]; then
	    	echo "input file found"
		elif [[ "$GENERATOR" == "gen_ee_hb" || "$GENERATOR" == "genBH" ]]; then
			echo "Config file not applicable"
		else
	    	echo $CONFIG_FILE" does not exist"
			echo "something went wrong with initialization"
	    	exit 1
    	fi

	fi
	echo "Begin writing beam.config"

	echo "PolarizationAngle $polarization_angle" > beam.config
	echo "PhotonBeamLowEnergy $GEN_MIN_ENERGY" >> beam.config
    echo "PhotonBeamHighEnergy $GEN_MAX_ENERGY" >> beam.config

	if [[ "$FLUX_TO_GEN" == "ccdb" ]]; then
		echo "CCDBRunNumber $RUN_NUMBER" >> beam.config
		echo "ROOTFluxFile $FLUX_TO_GEN" >> beam.config
		if [[ "$POL_TO_GEN" == "ccdb" ]]; then
			echo "ROOTPolFile $POL_TO_GEN" >> beam.config
		elif [[ "$POL_HIST" == "unset" ]]; then
			echo "PolarizationMagnitude $POL_TO_GEN" >> beam.config
		else
			echo "ROOTPolFile $POL_TO_GEN" >> beam.config
			echo "ROOTPolName $POL_HIST" >> beam.config
		fi
	elif [[ "$FLUX_TO_GEN" == "cobrems" ]]; then
    	echo "ElectronBeamEnergy $eBEAM_ENERGY" >> beam.config
    	echo "CoherentPeakEnergy $COHERENT_PEAK" >> beam.config
    	echo "Emittance  2.5.e-9" >> beam.config
    	echo "RadiatorThickness $radthick" >> beam.config
    	echo "CollimatorDiameter 0.00$colsize" >> beam.config
    	echo "CollimatorDistance  76.0" >> beam.config

		if [[ "$POL_TO_GEN" == "ccdb" ]]; then
			echo "Ignoring TPOL from ccdb in favor of cobrems generated values"
		elif [[ "$POL_HIST" == "cobrems" ]]; then
			echo "PolarizationMagnitude $POL_TO_GEN" >> beam.config
		elif [[ "$POL_HIST" != "unset" ]]; then
			echo "Ignoring TPOL from $POL_TO_GEN in favor of cobrems generated values"
		fi

    else
		echo "ROOTFluxFile $FLUX_TO_GEN" >> beam.config
		echo "ROOTFluxName $FLUX_HIST" >> beam.config
		if [[ "$POL_TO_GEN" == "ccdb" ]]; then
			echo "Can't use a flux file and Polarization from ccdb"
			echo "something went wrong with initialization"
			exit 1
		elif [[ "$POL_HIST" == "unset" ]]; then
			echo "PolarizationMagnitude $POL_TO_GEN" >> beam.config
		else
			echo "ROOTPolFile $POL_TO_GEN" >> beam.config
			echo "ROOTPolName $POL_HIST" >> beam.config
		fi
	fi
	echo "finished writing beam.config"
    if [[ "$GENERATOR" == "genr8" ]]; then
		echo "configuring genr8"
		STANDARD_NAME="genr8_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf

		replacementNum=`grep TEMPCOHERENT ./$STANDARD_NAME.conf | wc -l`
		#if [[ "$polarization_angle" == "-1.0" && "$COHERENT_PEAK" == "0." && $replacementNum != 0 && "1"=="0" ]]; then
		#	echo "Running genr8 with an AMO run number without supplying the energy desired to COHERENT_PEAK causes an inifinite loop."
		#	echo "Please specify the desired energy via the COHERENT_PEAK parameter and retry."
		#	exit 1
		#fi
    elif [[ "$GENERATOR" == "genr8_new" ]]; then
		echo "configuring new genr8"

		STANDARD_NAME="genr8_new_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "bggen" ]]; then
		echo "configuring bggen"
		STANDARD_NAME="bggen_"$STANDARD_NAME
		cp $MCWRAPPER_CENTRAL/Generators/bggen/particle.dat ./
		cp $MCWRAPPER_CENTRAL/Generators/bggen/pythia.dat ./
		cp $MCWRAPPER_CENTRAL/Generators/bggen/pythia-geant.map ./
		cp $CONFIG_FILE ./$STANDARD_NAME.conf

    elif [[ "$GENERATOR" == "genEtaRegge" ]]; then
		echo "configuring genEtaRegge"
		STANDARD_NAME="genEtaRegge_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "genScalarRegge" ]]; then
	        echo "configuring genScalerRegge"
		STANDARD_NAME="genScalarRegge_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_amp" ]]; then
		echo "configuring gen_amp"
		STANDARD_NAME="gen_amp_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_amp_V2" ]]; then
		echo "configuring gen_amp_V2"
		STANDARD_NAME="gen_amp_V2_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_2pi_amp" ]]; then
		echo "configuring gen_2pi_amp"
		STANDARD_NAME="gen_2pi_amp_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_omega_3pi" ]]; then
		echo "configuring gen_omega_3pi"
		STANDARD_NAME="gen_omega_3pi_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_omegapi" ]]; then
		echo "configuring gen_omegapi"
		STANDARD_NAME="gen_omegapi_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_vec_ps" ]]; then
		echo "configuring gen_vec_ps"
		STANDARD_NAME="gen_vec_ps_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_omega_radiative" ]]; then
		echo "configuring gen_omega_radiative"
		STANDARD_NAME="gen_omega_radiative_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_2pi_primakoff" ]]; then
		echo "configuring gen_2pi_primakoff"
		STANDARD_NAME="gen_2pi_primakoff_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "mc_gen" ]]; then
		echo "configuring mc_gen"
		STANDARD_NAME="mc_gen_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	 elif [[ "$GENERATOR" == "gen_2pi0_primakoff" ]]; then
        echo "configuring gen_2pi0_primakoff"
        STANDARD_NAME="gen_2pi0_primakoff_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_pi0" ]]; then
		echo "configuring gen_pi0"
		STANDARD_NAME="gen_pi0_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_compton" ]]; then
		echo "configuring gen_compton"
		STANDARD_NAME="gen_compton_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_compton_simple" ]]; then
		echo "configuring gen_compton_simple"
		STANDARD_NAME="gen_compton_simple_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_primex_eta_he4" ]]; then
		echo "configuring gen_primex_eta_he4"
		STANDARD_NAME="gen_primex_eta_he4_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_whizard" ]]; then
		echo "configuring gen_whizard"
		STANDARD_NAME="gen_whizard_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_npi" ]]; then
		echo "configuring gen_npi"
		STANDARD_NAME="gen_npi_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_2k" ]]; then
		echo "configuring gen_2k"
		STANDARD_NAME="gen_2k_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "bggen_jpsi" ]]; then
		echo "configuring bggen_jpsi"
		STANDARD_NAME="bggen_jpsi_"$STANDARD_NAME
		cp $MCWRAPPER_CENTRAL/Generators/bggen_jpsi/particle.dat ./
		cp $MCWRAPPER_CENTRAL/Generators/bggen_jpsi/pythia.dat ./
		cp $MCWRAPPER_CENTRAL/Generators/bggen_jpsi/pythia-geant.map ./
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "bggen_upd" ]]; then
		echo "configuring bggen_upd"
		STANDARD_NAME="bggen_upd_"$STANDARD_NAME
		cp $HALLD_SIM_HOME/src/programs/Simulation/bggen_upd/run/particles.ffr ./
		cp $HALLD_SIM_HOME/src/programs/Simulation/bggen_upd/run/pythia.dat ./
		cp $HALLD_SIM_HOME/src/programs/Simulation/bggen_upd/run/run_mcwrapper.ffr ./
		mkdir ./spec_fun
		cp $HALLD_SIM_HOME/src/programs/Simulation/bggen_upd/run/spec_fun/* ./spec_fun/
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "bggen_phi_ee" ]]; then
		echo "configuring bggen_phi_ee"
		STANDARD_NAME="bggen_phi_ee_"$STANDARD_NAME
		cp $MCWRAPPER_CENTRAL/Generators/bggen_phi_ee/particle.dat ./
		cp $MCWRAPPER_CENTRAL/Generators/bggen_phi_ee/pythia.dat ./
		cp $MCWRAPPER_CENTRAL/Generators/bggen_phi_ee/pythia-geant.map ./
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_ee" ]]; then
		echo "configuring gen_ee"
		STANDARD_NAME="gen_ee_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_ee_hb" ]]; then
		echo "configuring gen_ee_hb"
		STANDARD_NAME="gen_ee_hb_"$STANDARD_NAME
		echo "note: this generator is run completely from command line, thus no config file will be made and/or modified"
		cp $CONFIG_FILE ./cobrems.root
		cp $MCWRAPPER_CENTRAL/Generators/gen_ee_hb/CFFs_DD_Feb2012.dat ./
	elif [[ "$GENERATOR" == "particle_gun" ]]; then
		echo "configuring the particle gun"
		STANDARD_NAME="particle_gun_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
  elif [[ "$GENERATOR" == "geantBEAM" ]]; then
		echo "configuring geantBEAM"
		STANDARD_NAME="geantBeam"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "genBH" ]]; then
		echo "configuring genBH"
		STANDARD_NAME="genBH_"$STANDARD_NAME
		echo "note: this generator is run completely from command line, thus no config file will be made and/or modified"

		cp $CONFIG_FILE ./cobrems.root
	elif [[ "$GENERATOR" == "python" ]]; then
	        echo "configuring python script"
		STANDARD_NAME="python_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.py
	elif [[ "$GENERATOR" == "gen_gcf" ]]; then
		echo "configuring gen_gcf"
		STANDARD_NAME="gen_gcf_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_ALP" ]]; then
		echo "configuring gen_ALP"
		set STANDARD_NAME="gen_ALP_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_MF" ]]; then
		echo "configuring gen_MF"
		set STANDARD_NAME="gen_MF_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "gen_jpsi_hc" ]]; then
		echo "configuring gen_jpsi_hc"
		set STANDARD_NAME="gen_jpsi_hc_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
	elif [[ "$GENERATOR" == "genA" ]]; then
		echo "configuring genA"
		set STANDARD_NAME="genA_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf
    elif [[ "$GENERATOR" == "gen_coherent" ]]; then
		echo "configuring gen_coherent"
		set STANDARD_NAME="gen_coherent_"$STANDARD_NAME
		cp $CONFIG_FILE ./$STANDARD_NAME.conf

    fi

	if [[ "$gen_pre" != "file" ]]; then
    config_file_name=`basename "$CONFIG_FILE"`
    echo $config_file_name
    fi

	#RANDOMnum_forGeneration=`bash -c 'echo $RANDOM'`
	cp beam.config $STANDARD_NAME\_beam.conf

    if [[ "$GENERATOR" == "genr8" ]]; then
	echo "RUNNING GENR8"
	RUNNUM=$formatted_runNumber+$formatted_fileNumber
	#sed -i 's/TEMPCOHERENT/'$COHERENT_PEAK'/' $STANDARD_NAME.conf
	#sed -i 's/TEMPMAXE/'$GEN_MAX_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	# RUN genr8 and convert
	genr8 -r$formatted_runNumber -M$EVT_TO_GEN -A$STANDARD_NAME.ascii < $STANDARD_NAME.conf #$config_file_name
	generator_return_code=$?
	genr8_2_hddm -V"0 0 0 0" $STANDARD_NAME.ascii
	elif [[ "$GENERATOR" == "genr8_new" ]]; then
		echo "RUNNING NEW GENR8"
		RUNNUM=$formatted_runNumber+$formatted_fileNumber
		#sed -i 's/TEMPCOHERENT/'$COHERENT_PEAK'/' $STANDARD_NAME.conf
		# RUN genr8 and convert
		genr8_new -r$formatted_runNumber -M$EVT_TO_GEN -C$GEN_MIN_ENERGY,$GEN_MAX_ENERGY -o$STANDARD_NAME.gamp < $STANDARD_NAME.conf #$config_file_name
		generator_return_code=$?
		gamp_2_hddm -r$formatted_runNumber -V"0 0 0 0" $STANDARD_NAME.gamp
    elif [[ "$GENERATOR" == "bggen" ]]; then
	RANDOMnum=`bash -c 'echo $RANDOM'`

	echo "Random number used: "$RANDOMnum
	sed -i 's/TEMPTRIG/'$EVT_TO_GEN'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRUNNO/'$RUN_NUMBER'/' $STANDARD_NAME.conf
	sed -i 's/TEMPCOLD/'0.00$colsize'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRAND/'$RANDOMnum'/' $STANDARD_NAME.conf
	Fortran_eBEAM_ENRGY=`echo $eBEAM_ENERGY | cut -c -7`
	sed -i 's/TEMPELECE/'$Fortran_eBEAM_ENRGY'/' $STANDARD_NAME.conf
	Fortran_COHERENT_PEAK=`echo $COHERENT_PEAK | cut -c -7`
	sed -i 's/TEMPCOHERENT/'$Fortran_COHERENT_PEAK'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMINGENE/'$GEN_MIN_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMAXGENE/'$GEN_MAX_ENERGY'/' $STANDARD_NAME.conf

	ln -s $STANDARD_NAME.conf fort.15
	echo bggen
	bggen
	generator_return_code=$?
	mv bggen.hddm $STANDARD_NAME.hddm
	rm -f bggen.his
    elif [[ "$GENERATOR" == "genEtaRegge" ]]; then
	echo "RUNNING GENETAREGGE"

	sed -i 's/TEMPCOLD/'0.00$colsize'/' $STANDARD_NAME.conf
	sed -i 's/TEMPELECE/'$eBEAM_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPCOHERENT/'$COHERENT_PEAK'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRADTHICK/'"$radthick"'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMINGENE/'$GEN_MIN_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMAXGENE/'$GEN_MAX_ENERGY'/' $STANDARD_NAME.conf

	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf

	genEtaRegge -R$RUN_NUMBER -N$EVT_TO_GEN -O$STANDARD_NAME.hddm -I$STANDARD_NAME.conf
    generator_return_code=$?
    elif [[ "$GENERATOR" == "genScalarRegge" ]]; then
	echo "RUNNING GENETAREGGE"

	sed -i 's/TEMPCOLD/'0.00$colsize'/' $STANDARD_NAME.conf
	sed -i 's/TEMPELECE/'$eBEAM_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPCOHERENT/'$COHERENT_PEAK'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRADTHICK/'"$radthick"'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMINGENE/'$GEN_MIN_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMAXGENE/'$GEN_MAX_ENERGY'/' $STANDARD_NAME.conf

	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf

	genScalarRegge -R$RUN_NUMBER -N$EVT_TO_GEN -O$STANDARD_NAME.hddm -I$STANDARD_NAME.conf
    generator_return_code=$?
	elif [[ "$GENERATOR" == "mc_gen" ]]; then
	echo "RUNNING MC_GEN"
	python $HD_UTILITIES_HOME/psflux/plot_flux_ccdb.py -b $RUN_NUMBER -e $RUN_NUMBER
	MCGEN_FLUX_DIR=`printf './flux_%d_%d.ascii' "$RUN_NUMBER" "$RUN_NUMBER"`
	ROOTSCRIPT=`printf '$MCWRAPPER_CENTRAL/Generators/mc_gen/Flux_to_Ascii.C("flux_%s_%s.root")' "$RUN_NUMBER" "$RUN_NUMBER" `
	root -l -b -q $ROOTSCRIPT

	sed -i 's/TEMPTRIG/'$EVT_TO_GEN'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMINGENE/'$GEN_MIN_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMAXGENE/'$GEN_MAX_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's|TEMPFLUXDIR|'$MCGEN_FLUX_DIR'|' $STANDARD_NAME.conf
	sed -i 's|TEMPOUTNAME|'./'|' $STANDARD_NAME.conf
	MCGEN_Translator=`grep Translator $STANDARD_NAME.conf`


	echo mc_gen $STANDARD_NAME.conf
	mc_gen $STANDARD_NAME.conf
	rm flux_*

	mv *.ascii $STANDARD_NAME.ascii

	Translator=${MCGEN_Translator##!Translator:}

	GEN2HDDM_$Translator -r$RUN_NUMBER $STANDARD_NAME.ascii
	#if [[ "$MCGEN_Translator" == "\!Translator:ppbar" ]]; then
	#	GEN2HDDM_ppbar -r$RUN_NUMBER $STANDARD_NAME.ascii
	#elif [[ "$MCGEN_Translator" == "\!Translator:lamlambar" ]]; then
	#	GEN2HDDM_lamlambar -r$RUN_NUMBER $STANDARD_NAME.ascii
	#elif [[ "$MCGEN_Translator" == "\!Translator:jpsi" ]]; then
	#	GEN2HDDM_jpsi -r$RUN_NUMBER $STANDARD_NAME.ascii
	#fi

    generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_amp" ]]; then
	echo "RUNNING GEN_AMP"
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	echo "Beam Config:"
	more $STANDARD_NAME'_beam.conf'
	echo "pre run seds"
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		if [[ "$polarization_angle" == "-1.0" ]]; then
			sed -i 's/TEMPPOLFRAC/'0'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'0'/' $STANDARD_NAME.conf
		else
			sed -i 's/TEMPPOLFRAC/'.4'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'$polarization_angle'/' $STANDARD_NAME.conf
		fi

	echo gen_amp -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY  $optionals_line
	gen_amp -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_amp_V2" ]]; then
	echo "RUNNING GEN_AMP_V2"
     optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	echo "Beam Config:"
	more $STANDARD_NAME'_beam.config'
	echo "pre run seds"
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
                if [[ "$polarization_angle" == "-1.0" ]]; then
                        sed -i 's/TEMPPOLFRAC/'0'/' $STANDARD_NAME.conf
                        sed -i 's/TEMPPOLANGLE/'0'/' $STANDARD_NAME.conf
                else
                        sed -i 's/TEMPPOLFRAC/'.4'/' $STANDARD_NAME.conf
                        sed -i 's/TEMPPOLANGLE/'$polarization_angle'/' $STANDARD_NAME.conf
                fi
	echo gen_amp_V2 -ac $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	gen_amp_V2 -ac $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_2pi_amp" ]]; then
	echo "RUNNING GEN_2PI_AMP"
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
		if [[ "$polarization_angle" == "-1.0" ]]; then
			sed -i 's/TEMPPOLFRAC/'0'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'0'/' $STANDARD_NAME.conf
		else
			sed -i 's/TEMPPOLFRAC/'.4'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'$polarization_angle'/' $STANDARD_NAME.conf
		fi
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	echo gen_2pi_amp -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY  $optionals_line
	gen_2pi_amp -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_omega_3pi" ]]; then
	echo "RUNNING GEN_OMEGA_3PI"
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`

		if [[ "$polarization_angle" == "-1.0" ]]; then
			sed -i 's/TEMPPOLFRAC/'0'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'0'/' $STANDARD_NAME.conf
		else
			sed -i 's/TEMPPOLFRAC/'.4'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'$polarization_angle'/' $STANDARD_NAME.conf
		fi

	echo $optionals_line
	echo gen_omega_3pi -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -m $eBEAM_ENERGY -p $COHERENT_PEAK $optionals_line
	gen_omega_3pi -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -m $eBEAM_ENERGY -p $COHERENT_PEAK $optionals_line
    generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_omegapi" ]]; then
	echo "RUNNING GEN_OMEGAPI"
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
		if [[ "$polarization_angle" == "-1.0" ]]; then
			sed -i 's/TEMPPOLFRAC/'0'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'0'/' $STANDARD_NAME.conf
		else
			sed -i 's/TEMPPOLFRAC/'.4'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'$polarization_angle'/' $STANDARD_NAME.conf
		fi
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf

	echo gen_omegapi -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY  $optionals_line
	gen_omegapi -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_vec_ps" ]]; then
	echo "RUNNING GEN_VEC_PS"
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
		if [[ "$polarization_angle" == "-1.0" ]]; then
			sed -i 's/TEMPPOLFRAC/'0'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'0'/' $STANDARD_NAME.conf
		else
			sed -i 's/TEMPPOLFRAC/'.4'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'$polarization_angle'/' $STANDARD_NAME.conf
		fi
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf

	echo gen_vec_ps -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY  $optionals_line
	gen_vec_ps -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_omega_radiative" ]]; then
	echo "RUNNING GEN_OMEGA_RADIATIVE"
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`

		if [[ "$polarization_angle" == "-1.0" ]]; then
			sed -i 's/TEMPPOLFRAC/'0'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'0'/' $STANDARD_NAME.conf
		else
			sed -i 's/TEMPPOLFRAC/'.4'/' $STANDARD_NAME.conf
			sed -i 's/TEMPPOLANGLE/'$polarization_angle'/' $STANDARD_NAME.conf
		fi
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	echo $optionals_line
	echo gen_omega_radiative -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -m $eBEAM_ENERGY -p $COHERENT_PEAK $optionals_line
	gen_omega_radiative -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -m $eBEAM_ENERGY -p $COHERENT_PEAK $optionals_line
    generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_2pi_primakoff" ]]; then
	echo "RUNNING GEN_2PI_PRIMAKOFF"
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	echo $optionals_line
	echo gen_2pi_primakoff -c $STANDARD_NAME.conf -o  $STANDARD_NAME.hddm -hd  $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	gen_2pi_primakoff -c $STANDARD_NAME.conf -hd  $STANDARD_NAME.hddm -o  $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
    generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_2pi0_primakoff" ]]; then
        echo "RUNNING GEN_2PI0_PRIMAKOFF"
        optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
		echo $optionals_line
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
        echo gen_2pi0_primakoff -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
        gen_2pi0_primakoff -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
		generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_pi0" ]]; then
	echo "RUNNING GEN_PI0"
	optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	gen_pi0 -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK  -s $formatted_fileNumber -m $eBEAM_ENERGY $optionals_line
    generator_return_code=$?
        elif [[ "$GENERATOR" == "gen_compton" ]]; then
	echo "RUNNING GEN_COMPTON"
	optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	gen_compton -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK  -s $formatted_fileNumber -m $eBEAM_ENERGY $optionals_line
        elif [[ "$GENERATOR" == "gen_compton_simple" ]]; then
	echo "RUNNING GEN_COMPTON_SIMPLE"
	optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	gen_compton_simple -c $STANDARD_NAME'_beam.conf' -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK  -s $formatted_fileNumber -m $eBEAM_ENERGY $optionals_line
    generator_return_code=$?
        elif [[ "$GENERATOR" == "gen_primex_eta_he4" ]]; then
	echo "RUNNING GEN_PRIMEX_ETA_HE4"
	optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	gen_primex_eta_he4 -e $STANDARD_NAME.conf -c $STANDARD_NAME'_beam.conf' -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.txt -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -s $formatted_fileNumber -m $eBEAM_ENERGY $optionals_line
    generator_return_code=$?
        elif [[ "$GENERATOR" == "gen_whizard" ]]; then
	echo "RUNNING GEN_WHIZARD"
	optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	gen_whizard -e $STANDARD_NAME.conf -c $STANDARD_NAME'_beam.conf' -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.txt -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -s $formatted_fileNumber -m $eBEAM_ENERGY $optionals_line
    generator_return_code=$?
        elif [[ "$GENERATOR" == "gen_npi" ]]; then
	echo "RUNNING GEN_NPI"
	optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	echo $optionals_line
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	gen_npi -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK  -s $formatted_fileNumber -m $eBEAM_ENERGY $optionals_line
    generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_2k" ]]; then
	echo "RUNNING GEN_2K"
    optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
	#set RANDOMnum=`bash -c 'echo $RANDOM'`
	echo $optionals_line
	sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
	echo gen_2k -c $STANDARD_NAME.conf -o $STANDARD_NAME.hddm -hd $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	gen_2k -c $STANDARD_NAME.conf -hd $STANDARD_NAME.hddm -o $STANDARD_NAME.root -n $EVT_TO_GEN -r $RUN_NUMBER -a $GEN_MIN_ENERGY -b $GEN_MAX_ENERGY -p $COHERENT_PEAK -m $eBEAM_ENERGY $optionals_line
	generator_return_code=$?
	elif [[ "$GENERATOR" == "bggen_jpsi" ]]; then
	RANDOMnum=`bash -c 'echo $RANDOM'`
	echo "Random number used: "$RANDOMnum
	sed -i 's/TEMPTRIG/'$EVT_TO_GEN'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRUNNO/'$RUN_NUMBER'/' $STANDARD_NAME.conf
	sed -i 's/TEMPCOLD/'0.00$colsize'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRAND/'$RANDOMnum'/' $STANDARD_NAME.conf
	Fortran_eBEAM_ENRGY=`echo $eBEAM_ENERGY | cut -c -7`
	sed -i 's/TEMPELECE/'$Fortran_eBEAM_ENRGY'/' $STANDARD_NAME.conf
	Fortran_COHERENT_PEAK=`echo $COHERENT_PEAK | cut -c -7`
	sed -i 's/TEMPCOHERENT/'$Fortran_COHERENT_PEAK'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMINGENE/'$GEN_MIN_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMAXGENE/'$GEN_MAX_ENERGY'/' $STANDARD_NAME.conf

	ln -s $STANDARD_NAME.conf fort.15
	bggen_jpsi
	generator_return_code=$?
	mv bggen.hddm $STANDARD_NAME.hddm
	elif [[ "$GENERATOR" == "bggen_phi_ee" ]]; then
	RANDOMnum=`bash -c 'echo $RANDOM'`
	echo "Random number used: "$RANDOMnum
	sed -i 's/TEMPTRIG/'$EVT_TO_GEN'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRUNNO/'$RUN_NUMBER'/' $STANDARD_NAME.conf
	sed -i 's/TEMPCOLD/'0.00$colsize'/' $STANDARD_NAME.conf
	sed -i 's/TEMPRAND/'$RANDOMnum'/' $STANDARD_NAME.conf
	Fortran_eBEAM_ENRGY=`echo $eBEAM_ENERGY | cut -c -7`
	sed -i 's/TEMPELECE/'$Fortran_eBEAM_ENRGY'/' $STANDARD_NAME.conf
	Fortran_COHERENT_PEAK=`echo $COHERENT_PEAK | cut -c -7`
	sed -i 's/TEMPCOHERENT/'$Fortran_COHERENT_PEAK'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMINGENE/'$GEN_MIN_ENERGY'/' $STANDARD_NAME.conf
	sed -i 's/TEMPMAXGENE/'$GEN_MAX_ENERGY'/' $STANDARD_NAME.conf

	ln -s $STANDARD_NAME.conf fort.15
	bggen_jpsi
	generator_return_code=$?
	mv bggen.hddm $STANDARD_NAME.hddm
	elif [[ "$GENERATOR" == "bggen_upd" ]]; then
	RANDOMnum=`bash -c 'echo $RANDOM'`
	echo "Random number used: "$RANDOMnum
	sed -i 's/TEMPTRIG/'$EVT_TO_GEN'/' run_mcwrapper.ffr
	sed -i 's/TEMPRUNNO/'$RUN_NUMBER'/' run_mcwrapper.ffr
	sed -i 's/TEMPCOLD/'0.00$colsize'/' run_mcwrapper.ffr
	sed -i 's/TEMPRAND/'$RANDOMnum'/' run_mcwrapper.ffr
	Fortran_eBEAM_ENRGY=`echo $eBEAM_ENERGY | cut -c -7`
	sed -i 's/TEMPELECE/'$Fortran_eBEAM_ENRGY'/' run_mcwrapper.ffr
	Fortran_COHERENT_PEAK=`echo $COHERENT_PEAK | cut -c -7`
	sed -i 's/TEMPCOHERENT/'$Fortran_COHERENT_PEAK'/' run_mcwrapper.ffr
	sed -i 's/TEMPMINGENE/'$GEN_MIN_ENERGY'/' run_mcwrapper.ffr
	sed -i 's/TEMPMAXGENE/'$GEN_MAX_ENERGY'/' run_mcwrapper.ffr

	if grep -q "C EELEC" $STANDARD_NAME.conf ; then
    	sed -i 's/EELEC/C EELEC/g' run_mcwrapper.ffr
	fi

	if grep -q "C EPEAK" $STANDARD_NAME.conf ; then
    	sed -i 's/EPEAK/C EPEAK/g' run_mcwrapper.ffr
	fi

	if grep -q "C DCOLLIM" $STANDARD_NAME.conf ; then
    	sed -i 's/DCOLLIM/C DCOLLIM/g' run_mcwrapper.ffr
	fi


	ln -s $STANDARD_NAME.conf fort.15
    ln -s particles.ffr fort.16
    ln -s run_mcwrapper.ffr fort.17
	bggen_upd
	generator_return_code=$?
	mv bggen.hddm $STANDARD_NAME.hddm
	elif [[ "$GENERATOR" == "gen_ee" ]]; then
		echo "RUNNING GEN_EE"
		RANDOMnum=`bash -c 'echo $RANDOM'`
		echo "Random number used: "$RANDOMnum
		optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
		echo $optionals_line
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		gen_ee -d$STANDARD_NAME.conf -c$STANDARD_NAME'_beam.conf' -o$STANDARD_NAME.hddm -n$EVT_TO_GEN -z$RUN_NUMBER -l$GEN_MIN_ENERGY -u$GEN_MAX_ENERGY -r$RANDOMnum $optionals_line
		generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_ee_hb" ]]; then
		echo gen_ee_hb -N$RUN_NUMBER -n$EVT_TO_GEN
		gen_ee_hb -N$RUN_NUMBER -n$EVT_TO_GEN
		generator_return_code=$?
		mv genOut.hddm $STANDARD_NAME.hddm
	elif [[ "$GENERATOR" == "genBH" ]]; then
		RANDOMnum=`bash -c 'echo $RANDOM'`
		echo "Random number used: "$RANDOMnum
		echo genBH -n$EVT_TO_GEN -t$NUMTHREADS -m0.5 -e$GEN_MAX_ENERGY -r$RANDOMnum $STANDARD_NAME.hddm
		genBH -n$EVT_TO_GEN -t$NUMTHREADS -m0.5 -e$GEN_MAX_ENERGY -r$RANDOMnum $STANDARD_NAME.hddm

		sed -i 's/class="mc_s"/'class=\"s\"'/' $STANDARD_NAME.hddm
		generator_return_code=$?
	elif [[ "$GENERATOR" == "python" ]]; then
		RANDOMnum=`bash -c 'echo $RANDOM'`
	        optionals_line=`head -n 1 $STANDARD_NAME.py | sed -r 's/.//'`
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.py
		echo $GENERATOR $STANDARD_NAME.py --run $formatted_runNumber --nevents $EVT_TO_GEN --out $STANDARD_NAME.hddm --seed $RANDOMnum $optionals_line
		$GENERATOR $STANDARD_NAME.py --run $formatted_runNumber --nevents $EVT_TO_GEN --out $STANDARD_NAME.hddm --seed $RANDOMnum $optionals_line
		generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_gcf" ]]; then
		echo "RUNNING GEN_GCF"
		#optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
		#echo $optionals_line
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		echo gen_gcf -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber #$optionals_line
		gen_gcf -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber #$optionals_line
		generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_ALP" ]]; then
		echo "RUNNING GEN_ALP"
		#optionals_line=`head -n 1 $STANDARD_NAME.conf | sed -r 's/.//'`
		#echo $optionals_line
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		echo gen_ALP -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -R $STANDARD_NAME.root -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber #$optionals_line
		gen_ALP -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -R $STANDARD_NAME.root -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber #$optionals_line
		generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_MF" ]]; then
		echo "RUNNING GEN_MF"
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		echo gen_MF -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber
		gen_MF -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber 
		generator_return_code=$?
	elif [[ "$GENERATOR" == "gen_jpsi_hc" ]]; then
		echo "RUNNING GEN_jpsi_hc"
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		echo gen_jpsi_hc -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber
		gen_jpsi_hc -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber
		generator_return_code=$?
	elif [[ "$GENERATOR" == "genA" ]]; then
		echo "RUNNING GENA"
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		echo genA -C $STANDARD_NAME.conf -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber
		genA -C $STANDARD_NAME.conf -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber
		generator_return_code=$?
    elif [[ "$GENERATOR" == "gen_coherent" ]]; then
		echo "RUNNING GEN_COHERENT"
		sed -i 's/TEMPBEAMCONFIG/'$STANDARD_NAME'_beam.conf/' $STANDARD_NAME.conf
		echo gen_coherent -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber
		gen_coherent -C $STANDARD_NAME.conf -B $STANDARD_NAME'_beam.conf' -H $STANDARD_NAME.hddm -n $EVT_TO_GEN -z $RUN_NUMBER -r $formatted_fileNumber 
		generator_return_code=$?
	fi


	if [[ $generator_return_code != 0 ]]; then
				echo
				echo
				echo "Something went wrong with " "$GENERATOR"
				echo "status code: "$generator_return_code
				exit $generator_return_code
	fi

	if [[ ! -f ./$STANDARD_NAME.hddm && "$GENERATOR" != "particle_gun" && "$GENERATOR" != "geantBEAM" && "$gen_pre" != "file" ]]; then
		echo "something went wrong with generation"
		echo "An hddm file was not found after generation step.  Terminating MC production.  Please consult logs to diagnose"
		exit 11
	fi
    #GEANT/smearing
fi

#POST PROCESSING INSERTION POINT
if [[ "$GENERATOR_POST" != "No" ]]; then
	echo "RUNNING POSTPROCESSING "
#copy config locally
	post_return_code=-1
	echo $GENERATOR_POST_CONFIG
	echo $GENERATOR_POST_CONFIGEVT
	echo $GENERATOR_POST_CONFIGDEC
	if [[ "$GENERATOR_POST_CONFIG" != "Default" ]]; then
		cp $GENERATOR_POST_CONFIG ./post'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf
    if [[ ! -f ./post'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf ]]; then
      echo "Couldn't copy $GENERATOR_POST_CONFIG. Exit."
      exit 1
    fi
	fi

	if [[ "$GENERATOR_POST" == "decay_evtgen" ]]; then
		if [[ "$GENERATOR_POST_CONFIGEVT" != "Default" ]]; then
      cp $GENERATOR_POST_CONFIGEVT ./postevt'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf
      if [[ ! -f ./postevt'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf ]]; then
        echo "Couldn't copy $GENERATOR_POST_CONFIGEVT. Exit."
        exit 1
      fi
			export EVTGEN_PARTICLE_DEFINITIONS=$PWD/postevt'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf
		fi
		if [[ "$GENERATOR_POST_CONFIGDEC" != "Default" ]];then
      cp $GENERATOR_POST_CONFIGDEC ./postdec'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf
      if [[ ! -f ./postdec'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf ]]; then
        echo "Couldn't copy $GENERATOR_POST_CONFIGDEC. Exit."
        exit 1
      fi
			export EVTGEN_DECAY_FILE=$PWD/postdec'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf
		fi
		echo decay_evtgen -o$STANDARD_NAME'_decay_evtgen'.hddm -upost'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf $STANDARD_NAME.hddm
		decay_evtgen -o$STANDARD_NAME'_decay_evtgen'.hddm -upost'_'$GENERATOR_POST'_'$formatted_runNumber'_'$formatted_fileNumber.conf $STANDARD_NAME.hddm
		post_return_code=$?
		STANDARD_NAME=$STANDARD_NAME'_decay_evtgen'
	fi

	#do if/elses for running
	if [[ $post_return_code != 0 ]]; then
				echo
				echo
				echo "Something went wrong with " "$GENERATOR_POST"
				echo "status code: "$post_return_code
				exit $post_return_code
	fi


fi


if [[ "$GEANT" != "0" ]]; then
	echo "RUNNING GEANT"$GEANTVER

	if [[ `echo $eBEAM_ENERGY | grep -o "\." | wc -l` == 0 ]]; then
	    eBEAM_ENERGY=$eBEAM_ENERGY\.
	fi
	if [[ `echo $COHERENT_PEAK | grep -o "\." | wc -l` == 0 ]]; then
	    COHERENT_PEAK=$COHERENT_PEAK\.
	fi

	cp temp_Gcontrol.in $PWD/control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	chmod 777 $PWD/control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	RANDOMnumGeant=`shuf -i1-215 -n1`
	#a 4byte int: od -vAn -N4 -tu4 < /dev/urandom
	sed -i 's/TEMPRANDOM/'$RANDOMnumGeant'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	sed -i 's/TEMPELECE/'$eBEAM_ENERGY'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	if [[ "$polarization_angle" == "-1" ]]; then
		sed -i 's/TEMPCOHERENT/'0'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	else
		Fortran_COHERENT_PEAK=`echo $COHERENT_PEAK | cut -c -7`
		sed -i 's/TEMPCOHERENT/'$Fortran_COHERENT_PEAK'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	fi
	sed -i 's/TEMPIN/'$STANDARD_NAME.hddm'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	sed -i 's/TEMPRUNG/'$RUN_NUMBER'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	sed -i 's/TEMPOUT/'$STANDARD_NAME'_geant'$GEANTVER'.hddm/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	sed -i 's/TEMPTRIG/'$EVT_TO_GEN'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in

	if [[ $RUN_NUMBER -gt 70000 ]]; then
		sed -i 's/TEMPCKOV/'1'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
		echo "USING CKOV 1"
	else
		sed -i 's/TEMPCKOV/'0'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
		echo "USING CKOV 0"
	fi

	sed -i 's/TEMPGEANTAREA/'$GEANT_VERTEXT_AREA'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	sed -i 's/TEMPGEANTLENGTH/'$GEANT_VERTEXT_LENGTH'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in

	if [[ "$colsize" != "Not Needed" ]]; then
		sed -i 's/TEMPCOLD/'0.00$colsize'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	fi
	sed -i 's/TEMPRADTHICK/'"$radthick"'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	sed -i 's/TEMPBGTAGONLY/'$BGTAGONLY_OPTION'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	if [[ "$BGRATE_toUse" != "Not Needed" ]]; then
		sed -i 's/TEMPBGRATE/'$BGRATE_toUse'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	fi
	sed -i 's/TEMPNOSECONDARIES/'$GEANT_NOSCONDARIES'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in

	if [[ "$gen_pre" == "file" ]]; then
			skip_num=$((FILE_NUMBER * PER_FILE))
            sed -i 's/TEMPSKIP/'$skip_num'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
    elif [[ $GENERATOR == "particle_gun" ]]; then
			sed -i 's/INFILE/cINFILE/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
			sed -i 's/BEAM/cBEAM/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
			sed -i 's/TEMPSKIP/'0'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
			grep -v "/particle/" $STANDARD_NAME.conf >> control'_'$formatted_runNumber'_'$formatted_fileNumber.in
    elif [[ $GENERATOR == "geantBEAM" ]]; then
			sed -i 's/INFILE/cINFILE/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
			sed -i 's/TEMPSKIP/'0'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
			grep -v "/GENBEAM/" $STANDARD_NAME.conf >> control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	else
	    sed -i 's/TEMPSKIP/'0'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
        fi

	if [[ "$BKGFOLDSTR" == "None" ]]; then
	    echo "removing Beam Photon background from geant simulation"
	    sed -i 's/BGRATE/cBGRATE/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	    sed -i 's/BGGATE/cBGGATE/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	    sed -i 's/TEMPMINE/'$GEN_MIN_ENERGY'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	elif [[ "$BKGFOLDSTR" == "BeamPhotons" ]]; then
		sed -i 's/cBEAM/BEAM/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
		sed -i 's/TEMPMINE/0.0012/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	elif [[ "$BKGFOLDSTR" == "DEFAULT" || "$BKGFOLDSTR" == "Random" ||  "$bkgloc_pre" == "loc:" ]]  && [[ "$BGTAGONLY_OPTION" == "0" ]]; then
	    sed -i 's/BGRATE/cBGRATE/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	    sed -i 's/BGGATE/cBGGATE/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	    sed -i 's/TEMPMINE/'$GEN_MIN_ENERGY'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	else
	    sed -i 's/TEMPMINE/'$GEN_MIN_ENERGY'/' control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	fi

	echo "" >> control'_'$formatted_runNumber'_'$formatted_fileNumber.in
	echo END >> control'_'$formatted_runNumber'_'$formatted_fileNumber.in

	cp $PWD/control'_'$formatted_runNumber'_'$formatted_fileNumber.in $OUTDIR/configurations/geant/
	mv $PWD/control'_'$formatted_runNumber'_'$formatted_fileNumber.in $PWD/control.in

	if [[ "$GEANTVER" == "3" ]]; then

		hdgeant -xml=ccdb://GEOMETRY/main_HDDS.xml,run=$RUN_NUMBER
		geant_return_code=$?

	elif [[ "$GEANTVER" == "4" ]]; then
	    #make run.mac then call it below
	    rm -f run.mac

  		if [[ $gen_pre != "file" ]]; then
          if [[ "$GENERATOR_POST" != "No" ]]; then
              #STANDARD_NAME changed, remove '_decay_evtgen' for the search
              grep "/particle/" $(echo $STANDARD_NAME.conf | sed 's/_decay_evtgen//g') >> run.mac
          else
              grep "/particle/" $STANDARD_NAME.conf >> run.mac
          fi
  		fi
	    echo "/run/beamOn $EVT_TO_GEN" >> run.mac
	    echo "exit" >> run.mac

	    hdgeant4 -t$NUMTHREADS run.mac
		geant_return_code=$?
	    rm run.mac
	else
	    echo "INVALID GEANT VERSION"
	    exit 1
	fi

	if [[ $geant_return_code != 0 ]]; then
			echo
			echo
			echo "Something went wrong with hdgeant(4)"
			echo "status code: "$geant_return_code
			exit $geant_return_code
	fi

	if [[ ! -f ./$STANDARD_NAME'_geant'$GEANTVER'.hddm' ]]; then
		echo "An hddm file was not created by Geant.  Terminating MC production.  Please consult logs to diagnose"
		exit 12
	fi
	fi
	MCSMEAR_Flags=""
	if [[ "$SMEAR" == "0" ]]; then
		MCSMEAR_Flags="$MCSMEAR_Flags"" -s"
	fi

	if [[ "$NOSIPMSATURATION" == "1" ]]; then
		MCSMEAR_Flags="$MCSMEAR_Flags"" -T"
	fi

	if [[ "$MCSMEAR_NOTAG" == "1" ]]; then
			MCSMEAR_Flags="$MCSMEAR_Flags"" -t"
	fi

	echo $RECON and $SMEAR

	#if [[ "$RANDBGTAG" != "none" ]]; then

	#if [[ `ls $XRD_RANDOMS_URL/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm | head -c 1` != "r" ]]; then
	#	echo "JLab Connection test failed. Falling back to UConn...."
	#	#echo "attempting to copy the needed file from an alternate source..."
	#	#rsync scosg16.jlab.org:/osgpool/halld/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm ./
	#	export XRD_RANDOMS_URL=root://nod25.phys.uconn.edu/Gluex/rawdata/
	#	if [[ `ls $XRD_RANDOMS_URL/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm | head -c 1` != "r" ]]; then
	#		echo "Cannot connect to the file.  Disabling xrootd...."
	#		exit 232
	#	fi
	#fi
	#fi
if [[ "$GENERATOR" == "geantBEAM" ]]; then
  	echo "SKIP RUNNING MCSMEAR AND RECONSTRUCTION"
else
	#check if config file ends in .evio to decide whether or not smear needs to be run for conversion of simulation for reconstruction
	if [[ !("$GENR" == "0" && "$GEANT" == "0" && "$SMEAR" == "0" && "$CONFIG_FILE" != *.evio ) ]]; then
	echo "RUNNING MCSMEAR"
	if [[ "$GENR" == "0" && "$GEANT" == "0" ]]; then
		echo $GENERATOR
		geant_file=`echo $GENERATOR | cut -c 6-`
		echo $geant_file
		cp $geant_file ./$STANDARD_NAME'_geant'$GEANTVER'.hddm'
	fi
	if [[ "$BKGFOLDSTR" == "BeamPhotons" || "$BKGFOLDSTR" == "None" || "$BKGFOLDSTR" == "TagOnly" ]]; then
		echo "running MCsmear without folding in random background"
		mcsmear $MCSMEAR_Flags -PTHREAD_TIMEOUT_FIRST_EVENT=3600 -PTHREAD_TIMEOUT=3000 -o$STANDARD_NAME'_geant'$GEANTVER'_smeared.hddm' $STANDARD_NAME'_geant'$GEANTVER'.hddm'
		mcsmear_return_code=$?
	elif [[ "$BKGFOLDSTR" == "DEFAULT" || "$BKGFOLDSTR" == "Random" ]]; then
		rm -f count.py
		echo "RANDOM TRIGGER TOTAL EVENTS: " $RANDOM_TRIG_NUM_EVT
		if [[ $RANDOM_TRIG_NUM_EVT == -1 ]]; then
	   		echo "import hddm_s" > count.py
	   		echo "print(sum(1 for r in hddm_s.istream('$bkglocstring')))" >> count.py
	   		totalnum=$( $USER_PYTHON count.py )
	   		rm count.py
	   else
			totalnum=$RANDOM_TRIG_NUM_EVT
	   fi
		echo "TOTAL NUM SET:" $totalnum
	   if [[ $totalnum == -1 ]]; then
			echo "could not count file. exiting"
			exit 230
	   fi
		fold_skip_num=`echo "($FILE_NUMBER * $PER_FILE)%$totalnum" | $USER_BC`
		echo "skipping: "$fold_skip_num
		if [[ $MAKE_MC_USING_XROOTD == 0 ]]; then
			echo "mcsmear "$MCSMEAR_Flags " -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME"\_"geant$GEANTVER"\_"smeared.hddm $STANDARD_NAME"\_"geant$GEANTVER.hddm $bkglocstring"\:"1""+"$fold_skip_num
			mcsmear $MCSMEAR_Flags -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME\_geant$GEANTVER\_smeared.hddm $STANDARD_NAME\_geant$GEANTVER.hddm $bkglocstring\:1\+$fold_skip_num
			mcsmear_return_code=$?
		else
			xrdcopy $XRD_RANDOMS_URL/$RANDOMS_PREPEND/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm ./run$formatted_runNumber\_random.hddm
			echo "mcsmear $MCSMEAR_Flags -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME\_geant$GEANTVER\_smeared.hddm $STANDARD_NAME\_geant$GEANTVER.hddm ./run$formatted_runNumber\_random.hddm:1+$fold_skip_num"
            mcsmear $MCSMEAR_Flags -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME\_geant$GEANTVER\_smeared.hddm $STANDARD_NAME\_geant$GEANTVER.hddm ./run$formatted_runNumber\_random.hddm\:1\+$fold_skip_num
			mcsmear_return_code=$?
			#echo "mcsmear $MCSMEAR_Flags -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME\_geant$GEANTVER\_smeared.hddm $STANDARD_NAME\_geant$GEANTVER.hddm $XRD_RANDOMS_URL/random_triggers/$RANDBGTAG/run$formatted_runNumber\_random.hddm:1+$fold_skip_num"
            #mcsmear $MCSMEAR_Flags -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME\_geant$GEANTVER\_smeared.hddm $STANDARD_NAME\_geant$GEANTVER.hddm $XRD_RANDOMS_URL/random_triggers//$RANDBGTAG/run$formatted_runNumber\_random.hddm\:1\+$fold_skip_num
			rm -f ./run$formatted_runNumber\_random.hddm
		fi

	elif [[ "$bkgloc_pre" == "loc:" ]]; then
		rm -f count.py
		if [[ $RANDOM_TRIG_NUM_EVT == -1 ]]; then
	   echo "import hddm_s" > count.py
	   echo "print(sum(1 for r in hddm_s.istream('$bkglocstring')))" >> count.py
	   totalnum=`$USER_PYTHON count.py`
	   rm count.py
	   else
			totalnum=$RANDOM_TRIG_NUM_EVT
	   fi
		fold_skip_num=`echo "($FILE_NUMBER * $PER_FILE)%$totalnum" | $USER_BC`
		echo "mcsmear "$MCSMEAR_Flags " -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME"\_"geant$GEANTVER"\_"smeared.hddm $STANDARD_NAME"\_"geant$GEANTVER.hddm $bkglocstring"\:"1""+"$fold_skip_num
		mcsmear $MCSMEAR_Flags -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME\_geant$GEANTVER\_smeared.hddm $STANDARD_NAME\_geant$GEANTVER.hddm $bkglocstring\:1\+$fold_skip_num
		mcsmear_return_code=$?
	else
	    #trust the user and use their string
	    echo 'mcsmear -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o'$STANDARD_NAME'_geant'$GEANTVER'_smeared.hddm'' '$STANDARD_NAME'_geant'$GEANTVER'.hddm'' '$BKGFOLDSTR
	    mcsmear -PTHREAD_TIMEOUT_FIRST_EVENT=6400 -PTHREAD_TIMEOUT=6400 -o$STANDARD_NAME'_geant'$GEANTVER'_smeared.hddm' $STANDARD_NAME'_geant'$GEANTVER'.hddm' $BKGFOLDSTR
		mcsmear_return_code=$?
	fi

	if [[ $mcsmear_return_code != 0 ]]; then
		echo
		echo
		echo "Something went wrong with mcsmear"
		echo "status code: "$mcsmear_return_code
		exit $mcsmear_return_code
	fi

	    #run reconstruction
	if [[ "$CLEANGENR" == "1" ]]; then
		rm beam.config
		rm $STANDARD_NAME'_beam.conf'
		if [[ "$GENERATOR" == "genr8" ]]; then
		    rm *.ascii
		elif [[ "$GENERATOR" == "bggen" || "$GENERATOR" == "bggen_jpsi" || "$GENERATOR" == "bggen_phi_ee" ]]; then
		    rm particle.dat
		    rm pythia.dat
		    rm pythia-geant.map
			rm -f bggen.nt
		    unlink fort.15
		elif [[ "$GENERATOR" == "gen_ee_hb" ]]; then
				rm CFFs_DD_Feb2012.dat
				rm ee.ascii
				rm cobrems.root
				rm tcs_gen.root
		fi
		if [[ "$GENERATOR" != "particle_gun" && "$GENERATOR" != "geantBEAM" && "$gen_pre" != "file" ]]; then
			rm $STANDARD_NAME.hddm
		fi
		if [[ "$gen_pre" == "file" ]]; then
			rm $STANDARD_NAME.hddm
		fi
	    fi

		if [[ ! -f ./$STANDARD_NAME'_geant'$GEANTVER'_smeared.hddm' ]]; then
			echo "An hddm file was not created by mcsmear.  Terminating MC production.  Please consult logs to diagnose"
			exit 13
		fi

	fi

	    if [[ "$RECON" != "0" ]]; then
		echo "RUNNING RECONSTRUCTION"
		file_to_recon=$STANDARD_NAME'_geant'$GEANTVER'_smeared.hddm'

			if [[ "$GENR" == "0" && "$GEANT" == "0" && "$SMEAR" == "0" ]]; then
				file_to_recon="$CONFIG_FILE"
			fi

			additional_hdroot=""
			if [[ "$EXPERIMENT" == "CPP" ]]; then
				additional_hdroot="-PKALMAN:ADD_VERTEX_POINT=1"
			fi
			if [[ "$RECON_CALIBTIME" != "notime" ]]; then
					reconwholecontext="variation=$VERSION calibtime=$RECON_CALIBTIME"
					export JANA_CALIB_CONTEXT="$reconwholecontext"
			fi
			reaction_filter=""
			if [[ "$recon_pre" == "file" ]]; then
				echo "using config file: "$jana_config_file
				echo hd_root $file_to_recon --config=jana_config.cfg -PNTHREADS=$NUMTHREADS $additional_hdroot
				hd_root $file_to_recon --config=jana_config.cfg -PNTHREADS=$NUMTHREADS $additional_hdroot
				hd_root_return_code=$?
				reaction_filter=`grep ReactionFilter jana_config.cfg`
				#file_options = `tail jana_config.cfg -n+2` # get everything from line 2 on.  Lines counting starts with 1
				#echo "Reaction Filter: "$reaction_filter
				#echo "STATUS: " $hd_root_return_code
				if [[ "$reaction_filter" == "" || "$ANAENVIRONMENT" == "no_Analysis_env" ]]; then
					rm jana_config.cfg
				fi
			else

			declare -a pluginlist=("danarest" "monitoring_hists" "mcthrown_tree")

            if [[ "$CUSTOM_PLUGINS" != "None" ]]; then
				pluginlist=("${pluginlist[@]}" $CUSTOM_PLUGINS)
            fi


			PluginStr=""

            for plugin in "${pluginlist[@]}"; do
				PluginStr="$PluginStr""$plugin"","
            done

			PluginStr=`echo $PluginStr | sed -r 's/.{1}$//'`
            echo "Running hd_root with: ""$PluginStr"
			echo "hd_root ""$STANDARD_NAME"'_geant'"$GEANTVER"'_smeared.hddm'" -PPLUGINS=""$PluginStr ""-PNTHREADS=""$NUMTHREADS"
			hd_root $file_to_recon -PPLUGINS=$PluginStr -PNTHREADS=$NUMTHREADS -PTHREAD_TIMEOUT=500 $additional_hdroot
			hd_root_return_code=$?
		fi

		if [[ $hd_root_return_code != 0 ]]; then
				echo
				echo
				echo "Something went wrong with hd_root"
				echo "Status code: "$hd_root_return_code
				exit $hd_root_return_code
		fi

		if [[ -f dana_rest.hddm ]]; then
                    mv dana_rest.hddm dana_rest_$STANDARD_NAME.hddm
        fi
		if [[ "$ANAENVIRONMENT" != "no_Analysis_env" && "$reaction_filter" != "" || "$ANAENVIRONMENT" != "no_Analysis_env" && $ana_pre == "file" ]]; then
			echo "new env setup"
			source /group/halld/Software/build_scripts/gluex_env_clean.sh
			xmltest2=`echo $ANAENVIRONMENT | rev | cut -c -4 | rev`
			if [[ "$xmltest2" == ".xml" ]]; then
				source /group/halld/Software/build_scripts/gluex_env_jlab.sh $ANAENVIRONMENT
			else
				source $ANAENVIRONMENT
			fi

if [[ "$ccdbSQLITEPATH" != "no_sqlite" && "$ccdbSQLITEPATH" != "batch_default" && "$ccdbSQLITEPATH" != "jlab_batch_default" ]]; then
	if [[ `$USER_STAT --file-system --format=%T $PWD` == "lustre" ]]; then
		echo "Attempting to use sqlite on a lustre file system. This does not work.  Try running on a different file system!"
		exit 1
	fi
    cp $ccdbSQLITEPATH ./ccdb.sqlite
    export CCDB_CONNECTION=sqlite:///$PWD/ccdb.sqlite
    export JANA_CALIB_URL=$CCDB_CONNECTION
elif [[ "$ccdbSQLITEPATH" == "batch_default" ]]; then
    export CCDB_CONNECTION=sqlite:////group/halld/www/halldweb/html/dist/ccdb.sqlite
    export JANA_CALIB_URL=${CCDB_CONNECTION}
elif [[ "$ccdbSQLITEPATH" == "jlab_batch_default" ]]; then
		if [[ -f /usr/lib64/libXrdPosixPreload.so ]]; then
			#echo "stop...its xrdcopy time"
			xrdcopy $XRD_RANDOMS_URL/ccdb.sqlite ./
			export CCDB_CONNECTION=sqlite:///$PWD/ccdb.sqlite
		else
			ccdb_jlab_sqlite_path=`bash -c 'echo $((1 + RANDOM % 100))'`
		if [[ -f /work/halld/ccdb_sqlite/$ccdb_jlab_sqlite_path/ccdb.sqlite ]]; then
		#	cp /work/halld/ccdb_sqlite/$ccdb_jlab_sqlite_path/ccdb.sqlite $PWD/ccdb.sqlite
			export CCDB_CONNECTION sqlite:///$PWD/ccdb.sqlite
			#setenv CCDB_CONNECTION sqlite:////work/halld/ccdb_sqlite/$ccdb_jlab_sqlite_path/ccdb.sqlite
		else
			export CCDB_CONNECTION=mysql://ccdb_user@hallddb.jlab.org/ccdb
		fi
	fi

    export JANA_CALIB_URL=${CCDB_CONNECTION}

fi

if [[ "$rcdbSQLITEPATH" != "no_sqlite" && "$rcdbSQLITEPATH" != "batch_default" ]]; then
	if [[ `$USER_STAT --file-system --format=%T $PWD` == "lustre" ]]; then
		echo "Attempting to use sqlite on a lustre file system. This does not work.  Try running on a different file system!"
		exit 1
	fi
    cp $rcdbSQLITEPATH ./rcdb.sqlite
    export RCDB_CONNECTION=sqlite:///$PWD/rcdb.sqlite
elif [[ "$rcdbSQLITEPATH" == "batch_default" ]]; then
	#echo "keeping the RCDB on mysql now"
    export RCDB_CONNECTION=sqlite:////group/halld/www/halldweb/html/dist/rcdb.sqlite
fi


			echo "EMULATING ANALYSIS LAUNCH"
			echo "changed software to:  "`which hd_root`

			if [[ "$CUSTOM_ANA_PLUGINS" != "None" ]]; then
				if [[ $ana_pre == "file" ]]; then
					echo "Use $jana_ana_config_file"
				else #use list of plugins
					declare -a anapluginlist=( "monitoring_hists" )
					anapluginlist=( "${anapluginlist[@]}" "$CUSTOM_ANA_PLUGINS" )
					anaPluginStr=""
					for plugin in "${anapluginlist[@]}"; do
						anaPluginStr="$anaPluginStr""$plugin"","
					done
					anaPluginStr=`echo $anaPluginStr | sed -r 's/.{1}$//'` #remove last ","
					echo "PLUGINS ""$anaPluginStr" > ana_jana.cfg
				fi
			else
				echo "PLUGINS ReactionFilter" > ana_jana.cfg
				sed '/PLUGINS/d' jana_config.cfg >> ana_jana.cfg
			fi

			thrown_tree_check=`grep mcthrown_tree ana_jana.cfg`
			if [[ $thrown_tree_check != "" ]]; then
				echo
				echo
				echo "WARNING: You have the mcthrown_tree plugin in your jana config file for the analysis launch (see below)!"
				echo "         This will overwrite the previous thrown_tree and the file will not contain ALL thrown information."
				echo
				echo
			fi

			cat ana_jana.cfg

			hd_root dana_rest_$STANDARD_NAME.hddm --config=ana_jana.cfg -PNTHREADS=$NUMTHREADS -PTHREAD_TIMEOUT=500 -o hd_root_ana.root
			anahd_root_return_code=$?

			if [[ $anahd_root_return_code != 0 ]]; then
			echo
			echo
			echo "Something went wrong with ana_hd_root"
			echo "Status code: "$anahd_root_return_code
			exit $anahd_root_return_code
			fi
			rm jana_config.cfg
			rm ana_jana.cfg

			if [[ -f dana_rest.hddm ]]; then
            	mv dana_rest.hddm dana_rest_ana_$STANDARD_NAME.hddm
			fi
		fi
fi
		if [[ "$CLEANGEANT" == "1" && "$GEANT" == "1" ]]; then
		    rm $STANDARD_NAME'_geant'$GEANTVER'.hddm'
		    rm control.in
		    rm -f geant.hbook
		    rm -f hdgeant.rz
		    if [[ "$PWD" != "$MCWRAPPER_CENTRAL" ]]; then
			rm temp_Gcontrol.in
		    fi

		fi

		if [[ "$CLEANSMEAR" == "1" && "$SMEAR" == "1" ]]; then
		    rm $STANDARD_NAME'_geant'$GEANTVER'_smeared.hddm'
		fi
		rm -rf smear.root

		if [[ "$CLEANRECON" == "1" ]]; then
		    rm dana_rest*
		fi

		rootfiles=$(ls *.root)
		filename_root=""
		for rootfile in $rootfiles; do
		    filename_root=`echo $rootfile | sed -r 's/.{5}$//'`
		    filetomv="$rootfile"
			filecheck=`echo $current_files | grep -c $filetomv`

			if [[ "$filecheck" == "0" ]]; then
				echo $filetomv
			    hdroot_test=`echo $filetomv | grep 'hd_root_\|hd_root.root'`
				thrown_test=`echo $filetomv | grep tree_thrown`
				gen_test=`echo $filetomv | grep gen`
				reaction_test=`echo $filetomv | grep tree_`
				std_name_test=`echo $filetomv | grep $STANDARD_NAME`
				#echo hdroot_test = $hdroot_test
				if [[ $hdroot_test != "" ]]; then
					if [[ ! -d "$OUTDIR/root/monitoring_hists/" ]]; then
    					mkdir $OUTDIR/root/monitoring_hists/
					fi
					mv $PWD/$filetomv $OUTDIR/root/monitoring_hists/$filename_root\_$STANDARD_NAME.root
				elif [[ $thrown_test != "" ]]; then
					if [[ ! -d "$OUTDIR/root/thrown/" ]]; then
						mkdir $OUTDIR/root/thrown/
					fi
					mv $PWD/$filetomv $OUTDIR/root/thrown/$filename_root\_$STANDARD_NAME.root
				elif [[ $reaction_test != "" ]]; then
					if [[ ! -d "$OUTDIR/root/trees/" ]]; then
						mkdir $OUTDIR/root/trees/
					fi
					mv $PWD/$filetomv $OUTDIR/root/trees/$filename_root\_$STANDARD_NAME.root
				elif [[ $gen_test != "" ]]; then
					if [[ ! -d "$OUTDIR/root/generator/" ]]; then
						mkdir $OUTDIR/root/generator/
					fi
					if [[ $std_name_test != "" ]]; then
						# echo "generator output root file $filename_root.root already contains $STANDARD_NAME"
						mv $PWD/$filetomv $OUTDIR/root/generator/$filename_root.root
					else
						mv $PWD/$filetomv $OUTDIR/root/generator/$filename_root\_$STANDARD_NAME.root
					fi
				else
					mv $PWD/$filetomv $OUTDIR/root/$filename_root\_$STANDARD_NAME.root
				fi
			fi
		done
	fi

rm -rf .hdds_tmp_*
rm -rf ccdb.sqlite
rm -rf rcdb.sqlite

if [[ "$gen_pre" != "file" && "$GENERATOR" != "gen_ee_hb" && "$GENR" == "1" ]]; then
	mv $PWD/*.conf $OUTDIR/configurations/generation/
fi
if [[ "$GENERATOR" == "python" ]]; then
        mv $PWD/*.py $OUTDIR/configurations/generation/
fi
hddmfiles=$(ls | grep .hddm)
if [[ "$hddmfiles" != "" ]]; then
	for hddmfile in $hddmfiles; do
		filetomv="$hddmfile"
		filecheck=`echo $current_files | grep -c $filetomv`
		if [[ "$filecheck" == "0" ]]; then
    		mv $hddmfile $OUTDIR/hddm/
		fi
	done
fi


echo `ls`

if [[ "$BATCHSYS" == "OSG" ]]; then
#copy the OUT_DIR back to location via xrdcp
echo "xrd version:" 
echo `xrdcp --version`

#get everything after the last / in PROJECT_DIR_NAME
project_dir_name=`echo $PROJECT_DIR_NAME | sed -r 's/.*\///'`
export COPYBACK_DIR=xroots://dtn-gluex.jlab.org//gluex/mcwrap/REQUESTEDMC_OUTPUT/$project_dir_name/
echo `ls -lbh $OUTDIR`


#echo "Testing a single file"
#echo "TEST DATA" >> ./test.txt
#ls
#echo "xrdcp -f ./test.txt $COPYBACK_DIR"
#xrdcp -f ./test.txt $COPYBACK_DIR

echo "ping server"
xrdfs dtn-gluex.jlab.org query stats l
echo "check token"
httokendecode -H
#echo "ls check"
#echo `xrdfs dtn-gluex.jlab.org ls /gluex/mcwrap/REQUESTEDMC_OUTPUT/`
echo "making directory"
echo "xrdfs dtn-gluex.jlab.org mkdir /gluex/mcwrap/REQUESTEDMC_OUTPUT/$project_dir_name"
xrdfs dtn-gluex.jlab.org mkdir /gluex/mcwrap/REQUESTEDMC_OUTPUT/$project_dir_name

echo "Copying back to $COPYBACK_DIR"
echo "xrdcp -rfv $OUTDIR $COPYBACK_DIR"
xrdcp -rfv -d 3 $OUTDIR $COPYBACK_DIR
transfer_return_code=$?
if [[ $transfer_return_code != 0 ]]; then
	echo
	echo
	echo "Something went wrong with xrdcp"
	echo "status code: "$transfer_return_code
	exit $transfer_return_code
fi
fi
cd ..

rm -rf .hdds_tmp_*

if [[ `ls $RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER} | wc -l` == 0 ]]; then
	rm -rf $RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER}
else
	echo "MOVING AND/OR CLEANUP FAILED"
	echo `ls $RUNNING_DIR/${RUN_NUMBER}_${FILE_NUMBER}`
fi

#mv $PWD/*.root $OUTDIR/root/ #just in case
echo `date`
echo "Successfully completed"
