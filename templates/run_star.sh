
echo ${params.mod.star}
${params.mod.star}
echo ${params.mod.samtools}
${params.mod.samtools}
echo ${params.mod.subread}
${params.mod.subread}

echo "Run STAR"
STAR --outSAMtype BAM SortedByCoordinate \
     --genomeDir ${params.star.db} \
     --outFileNamePrefix ${fq.name}__ \
     --readFilesCommand zcat \
     --outFilterScoreMinOverLread 0.3 \
     --outFilterMatchNminOverLread 0.3 \
     --limitBAMsortRAM 10000000000 \
     --runThreadN ${task.cpus} \
     --chimSegmentMin 18 \
     --readFilesIn $fq > star.stdout 2> star.stderr

echo "Index bam file"
samtools index ${fq.name}__Aligned.sortedByCoord.out.bam
    
echo "Feature Counts"
featureCounts \
    -g gene_name -a ${params.star.gtf} \
    -o ${fq.name}__counts ${fq.name}__Aligned.sortedByCoord.out.bam 

echo "save space - gzip count output"
gzip -9 "${fq.name}__counts"
