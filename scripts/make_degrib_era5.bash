#!/bin/bash 
umask 022


if [ $# -ne 4 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: ERA5"
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Make Degrib ERA5 ----"
echo ""

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=ERA5
EXP5=ERA-interim.pl
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
#-------------------------------------------------------




# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------
mkdir -p ${DATAIN}/${YYYYMMDDHHi}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs

if [ "$HOSTNAME" = "egeon" ]; then
    mkdir -p ${HOME}/local/lib64
    cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
    cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
fi


#chamada da API de download do ERA5
if [ ! -s ${SCRIPTS}/dado_era5/era5_${YYYYMMDDHHi}_pl.grib ] && [ ! -s ${SCRIPTS}/dado_era5/era5_${YYYYMMDDHHi}_sl.grib ]
then
      mkdir -p ${SCRIPTS}/dado_era5
      python3.12 download_era5_grib.py ${YYYYMMDDHHi}
      mv ${SCRIPTS}/era5_${YYYYMMDDHHi}* ${SCRIPTS}/dado_era5
fi
#fim do download

BNDDIR=${SCRIPTS}/dado_era5

if [ ! -s ${BNDDIR}/era5_${YYYYMMDDHHi}_pl.grib ] || [ ! -s ${BNDDIR}/era5_${YYYYMMDDHHi}_sl.grib ]
then
      echo -e "${RED}==>${NC}Condicao de contorno inexistente !"
      exit 1            
   
fi



files_needed=("${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/Vtable.${EXP5}" "${EXECS}/ungrib.exe" "${BNDDIR}/era5_${YYYYMMDDHHi}_pl.grib" "${BNDDIR}/era5_${YYYYMMDDHHi}_sl.grib" )

for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done



cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/Vtable.${EXP5} ${DIRRUN}/Vtable
cp -f ${EXECS}/ungrib.exe ${DIRRUN}
cp -f ${SCRIPTS}/namelists/namelist.wps.TEMPLATE ${DIRRUN}/namelist.wps.TEMPLATE
cp -f ${BNDDIR}/era5_${YYYYMMDDHHi}* ${DIRRUN}
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
cp -f ${SCRIPTS}/link_grib.csh ${DIRRUN}
rm -f ${DIRRUN}/degrib_era5.bash 
#sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,ERA5,g" ${DIRRUN}/namelist.wps.TEMPLATE > ${DIRRUN}/namelist.wps

if [ ${SCHEDULER_SYSTEM} != "GENERIC" ]
then
   sed -e "s,#JOBNAME#,${DEGRIB_jobname},g;
   s,#NNODES#,${DEGRIB_nnodes},g;
   s,#NCPUS#,${DEGRIB_ncpus},g;
   s,#NTASKS#,${DEGRIB_ncores},g;
   s,#NTASKSPNODE#,${DEGRIB_ncpn},g;
   s,#NTHREADS#,${DEGRIB_nthreads},g;
   s,#PARTITION#,${DEGRIB_QUEUE},g;
   s,#WALLTIME#,${DEGRIB_walltime},g;
   s,#OUTPUTJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.o,g;
   s,#ERRORJOB#,${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/degrib.e,g" \
   ${SCRIPTS}/stools/submit_${SYSTEM_KEY}.bash_TEMPLATE > ${DIRRUN}/degrib_era5.bash 
else
   echo "#!/bin/bash " > ${DIRRUN}/degrib_era5.bash 
fi



cat << EOF0 >> ${DIRRUN}/degrib_era5.bash 

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

cd ${DIRRUN}

. ${SCRIPTS}/setenv.bash

ldd ungrib.exe

rm -f GRIBFILE.* namelist.wps

sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,ERA,g" ${DIRRUN}/namelist.wps.TEMPLATE > ${DIRRUN}/namelist.wps

./link_grib.csh ${DIRRUN}/era5_${YYYYMMDDHHi}*.grib

#./link_grib.csh ${DIRRUN}/era5_${YYYYMMDDHHi}_pl.grib

chmod 755 *

date
echo "submetendo jobs ungrib"

time mpirun -np 1 ./ungrib.exe


date


grep "Successful completion of program ungrib.exe" ${DIRRUN}/ungrib.log >& /dev/null

if [ \$? -ne 0 ]; then
   echo "  BUMMER: Ungrib generation failed for some yet unknown reason."
   echo " "
   tail -10 ${DIRRUN}/ungrib.log
   echo " "
   exit 21
fi

#
# clean up and remove links
#
   cp ungrib.log ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/ungrib.${start_date}.log
   cp namelist.wps ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/namelist.${start_date}.wps
   cp  ERA\:${start_date:0:13} ${DATAOUT}/${YYYYMMDDHHi}/Pre
 



echo "End of degrib Job"


EOF0
chmod a+x ${DIRRUN}/degrib_era5.bash


case "${SCHEDULER_SYSTEM}" in
   SLURM)
      echo -e  "${GREEN}==>${NC} Sbatch degrib_era5.bash...\n"
      cd ${DIRRUN}
      sbatch --wait ${DIRRUN}/degrib_era5.bash
        ;;
   PBS)
      echo -e  "${GREEN}==>${NC} qsub degrib_era5.bash...\n"
      cd ${DIRRUN}
      qsub -W block=true ${DIRRUN}/degrib_era5.bash
       ;;
#    GENERIC)
#      echo "Nenhum gerenciador detectado"
#      ${DIRRUN}/degrib_era5.bash
#      ;;
esac


files_ungrib=("${EXP}:${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}")
for file in "${files_ungrib[@]}"
do
  if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/${file} ] 
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails! At least the file ${file} was not generated at ${DATAIN}/${YYYYMMDDHHi}. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DATAOUT}/logs/degrib.* .\n"
    echo -e  "${RED}==>${NC} Exiting script. \n"
    exit -1
  fi
done

cp ${DIRRUN}/degrib_era5.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*
rm -fr ${DIRRUN}
