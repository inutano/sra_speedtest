#!/home/iNut/local/bin/zsh
#
# time file transfer from NCBI, EBI, and DDBJ with various transfer protocol.
# calc avg time send it to stdout
#
# requirement: SRA_Accessions.tab from ftp.ncbi.nlm.nih.gov/sra/reports/Metadata
#
###################################################################################

# time format (set as showing total time by second only)
TIMEFMT="%E"

### change here to target Run id
# set ids
run_id="DRR000983" # SRR073092

# related ids
run_head=`echo ${run_id} | sed -e 's:[0-9]\{3\}$::'`
run_db=`echo ${run_id} | sed -e 's:[0-9]\{6\}::'`
run_db_lc=`echo ${run_db} | tr '[:upper:]' '[:lower:]'`

converter=`grep ${run_id} ./SRA_Accessions.tab`

acc_id=`echo ${converter} | cut -f 2`
acc_head=`echo ${acc_id} | sed -e 's:[0-9]\{3\}$::'`

exp_id=`echo ${converter} | cut -f 11`
exp_head=`echo ${exp_id} | sed -e 's:[0-9]\{3\}$::'`
exp_db=`echo ${exp_id} | sed -e 's:[0-9]\{6\}$::'`

# path to aspera connect
aspera="~/.aspera/connect"
aspera_putty="${aspera}/etc/asperaweb_id_dsa.putty"

# preparing target directories
if [ ! -e ./ncbi ] ; then
	mkdir ./ncbi
fi
if [ ! -e ./ebi ] ; then
	mkdir ./ebi
fi
if [ ! -e ./ddbj ] ; then
	mkdir ./ddbj
fi

## NCBI

# litesra ncbi ftp
ncbiftp="ftp.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/litesra/${run_db}/${run_head}"
for i in 1 2 3 ; do
	for u in 1 2 4 8 ; do
		rm -fr "./ncbi/${run_id}"
		(time lftp -c "open ${ncbiftp} && mirror --parallel=${u} ${run_id} ./ncbi/") 2>&1 | sed -e "s:s$::" > ./ncbi/${run_id}_ncbiftp_p${u}_${i}
	done
done

for u in 1 2 4 8 ; do
	echo "litesra from ncbi mirror --parallel=${u}. avg;"
	1=`cat ./ncbi/${run_id}_ncbiftp_p${u}_1`
	2=`cat ./ncbi/${run_id}_ncbiftp_p${u}_2`
	3=`cat ./ncbi/${run_id}_ncbiftp_p${u}_3`
	ruby -e "puts (${1} + ${2} + ${3}) / 3"
done

# litesra ncbi aspera
aspera_ncbi_path="anonftp@ftp-trace.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/litesra/${run_db}/${run_head}/${run_id}"
for i in 1 2 3 ; do
	rm -fr "./ncbi/${run_id}"
	(time ${aspera}/bin/ascp -q -k1 -QT -i ${aspera_putty} ${aspera_ncbi_path} ./ncbi) 2>&1 | sed -e "s:s$::" > ./ncbi/${run_id}_ncbi_aspera_${i}
done

echo "litesra from ncbi, aspera connect. avg;"
1=`cat ./ncbi/${run_id}_ncbi_aspera_1`
2=`cat ./ncbi/${run_id}_ncbi_aspera_2`
3=`cat ./ncbi/${run_id}_ncbi_aspera_3`
ruby -e "puts (${1} + ${2} + ${3}) / 3"


## EBI

# fq ebi ftp
ebifqftp="ftp.sra.ebi.ac.uk/vol1/fastq/${run_head}"
for i in 1 2 3 ; do
	for u in 1 2 4 8 ; do
		rm -fr "./ebi/${run_id}"
		(time lftp -c "open ${ebifqftp} && mirror --parallel=${u} ${run_id} ./ebi/") 2>&1 | sed -e 's:s$::' > ./ebi/${run_id}_ebi_fq_ftp_p${u}_${i}
	done
done

for u in 1 2 4 8 ; do
	echo "fq.gz from ebi, mirror --parallel=${u}. avg;"
	1=`cat ./ebi/${run_id}_ebi_fq_ftp_p${u}_1`
	2=`cat ./ebi/${run_id}_ebi_fq_ftp_p${u}_2`
	3=`cat ./ebi/${run_id}_ebi_fq_ftp_p${u}_3`
	ruby -e "puts (${1} + ${2} + ${3}) / 3"
done

# fq ebi aspera
aspera_ebi_path_fq="era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/${run_head}/${run_id}"
for i in 1 2 3 ; do
	rm -fr "./ebi/${run_id}"
	(time ${aspera}/bin/ascp -q -k1 -QT -i ${aspera_putty} ${aspera_ebi_path_fq} ./ebi) 2>&1 | sed -e 's:s$::' > ./ebi/${run_id}_ebi_fq_aspera_${i}
done

echo "fq.gz from ebi, aspera connect. avg;"
1=`cat ./ebi/${run_id}_ebi_fq_aspera_1`
2=`cat ./ebi/${run_id}_ebi_fq_aspera_2`
3=`cat ./ebi/${run_id}_ebi_fq_aspera_3`
ruby -e "puts (${1} + ${2} + ${3}) / 3"


# litesra ebi ftp
ebilsftp="ftp.sra.ebi.ac.uk/vol1/${run_db_lc}/${run_head}"
for i in 1 2 3 ; do
	for u in 1 2 4 8 ; do
		rm -fr "./ebi/${run_id}"
		(time lftp -c "open ${ebilsftp} && pget -O ./ebi -n ${u} ${run_id}") 2>&1 | sed -e 's:s$::' > ./ebi/${run_id}_ebi_ls_ftp_p${u}_${i}
	done
done

for u in 1 2 4 8 ; do
	echo "litesra from ebi, pget -n ${u}. avg;"
	1=`cat ./ebi/${run_id}_ebi_ls_ftp_p${u}_1`
	2=`cat ./ebi/${run_id}_ebi_ls_ftp_p${u}_2`
	3=`cat ./ebi/${run_id}_ebi_ls_ftp_p${u}_3`
	ruby -e "puts (${1} + ${2} + ${3}) / 3"
done

# litesra ebi aspera
aspera_ebi_path_ls="era-fasp@fasp.sra.ebi.ac.uk:/vol1/${run_db_lc}/${run_head}/${run_id}"
for i in 1 2 3 ; do
	rm -fr "./ebi/${run_id}"
	(time ${aspera}/bin/ascp -q -k1 -QT -i ${aspera_putty} ${aspera_ebi_path_ls} ./ebi) 2>&1 | sed -e "s:s$::" > ./ebi/${run_id}_ebi_ls_aspera_${i}
done

echo "litesra from ebi, aspera connect. avg;"
1=`cat ./ebi/${run_id}_ebi_ls_aspera_1`
2=`cat ./ebi/${run_id}_ebi_ls_aspera_2`
3=`cat ./ebi/${run_id}_ebi_ls_aspera_3`
ruby -e "puts (${1} + ${2} + ${3}) / 3"

## DDBJ
ddbjftpbase="ftp.ddbj.nig.ac.jp/ddbj_database/dra"

# fq ddbj ftp
ddbjfqftp="${ddbjftpbase}/fastq/${acc_head}/${acc_id}"
for i in 1 2 3 ; do
	for u in 1 2 4 8 ; do
		rm -fr "./ddbj/${exp_id}"
		(time lftp -c "open ${ddbjfqftp} && mirror --parallel=${u} ${exp_id} ./ddbj/") 2>&1 | sed -e "s:s$::" > ./ddbj/${run_id}_ddbj_fq_p${u}_${i}
	done
done

for u in 1 2 4 8 ; do
	echo "fq from ddbj, mirror --parallel=${u}. avg;"
	1=`cat ./ddbj/${run_id}_ddbj_fq_p${u}_1`
	2=`cat ./ddbj/${run_id}_ddbj_fq_p${u}_2`
	3=`cat ./ddbj/${run_id}_ddbj_fq_p${u}_3`
	ruby -e "puts (${1} + ${2} + ${3}) / 3"
done

# litesra ddbj ftp
ddbjlsftp="${ddbjftpbase}/sralite/ByExp/litesra/${exp_db}/${exp_head}/${exp_id}"
for i in 1 2 3 ; do
	for u in 1 2 4 8 ; do
		rm -fr "./ddbj/${run_id}"
		(time lftp -c "open ${ddbjlsftp} && mirror --parallel=${u} ${run_id} ./ddbj/") 2>&1 | sed -e "s:s$::" > ./ddbj/${run_id}_ddbj_ls_p${u}_${i}
	done
done

for u in 1 2 4 8 ; do
	echo "litesra from ddbj, mirror --parallel=${u}. avg;"
	1=`cat ./ddbj/${run_id}_ddbj_ls_p${u}_1`
	2=`cat ./ddbj/${run_id}_ddbj_ls_p${u}_2`
	3=`cat ./ddbj/${run_id}_ddbj_ls_p${u}_3`
	ruby -e "puts (${1} + ${2} + ${3}) / 3"
done
