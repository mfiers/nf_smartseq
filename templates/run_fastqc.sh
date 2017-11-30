${params.mod.fastqc}

ln -s ${fq} in.fastq.gz
fastqc -q -nogroup -o . in.fastq.gz

unzip -p in_fastqc.zip in_fastqc/summary.txt \
    | awk 'BEGIN {FS="\\t"; OFS="\\t"}; {print "${fq.name}", \$2,\$1}' \
    | tr " " "_" \
         > fqsummary.tsv

unzip -p in_fastqc.zip in_fastqc/fastqc_data.txt \
    | sed -e '/Per tile sequence quality/,\$d' \
    | grep -E '^1\\s|^5\\s|^10\\s|^20\\s|^30\\s|^Total|^Sequence|^Enco' \
    | awk 'BEGIN {FS="\\t"; OFS="\\t"}; {print "${fq.name}", \$1,\$2}' \
    | tr " " "_" \
         >> ${fq.name}.fastqc.tsv
    
