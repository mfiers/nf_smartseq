#!/usr/bin/env nextflow

import java.util.regex.Pattern

params.folders = {}
params.folders.base = '.'
params.folders.sample_md = "910.sample_md"
params.folders.sequence_md = "909.sequence_md"
params.folders.rawcount = "490.rawcount"


params.fastq_ext = '.fastq.gz'
params.sample_regex = "(.*)${params.fastq_ext}"
params.sequence_samplesheet_file = "samplesheet.tsv"


params.mod = {}
params.mod.cmd      = 'module load'
params.mod.star     = "${params.mod.cmd} STAR/2.5.1b-foss-2014a"
params.mod.samtools = "${params.mod.cmd} SAMtools/1.3.1-foss-2014a"
params.mod.subread  = "${params.mod.cmd} Subread/1.5.1"
params.mod.fastqc   = "${params.mod.cmd} FastQC/0.11.5"


params.star = {}
params.star.db = '/ddn1/vol1/staging/leuven/stg_00002/db/mouse/mm10/star'
params.star.gtf =  '/ddn1/vol1/staging/leuven/stg_00002/db/mouse/mm10/annotation.gtf'


prep_outfolder = { dirname -> r = file("${params.folders.base}/" + dirname);
    		              r.mkdirs()
                              r }

folders = {}
folders.base = file(params.folders.base)
folders.base.mkdirs()
folders.sample_md = prep_outfolder(params.folders.sample_md)
folders.sequence_md = prep_outfolder(params.folders.sequence_md)
folders.rawcount_md = prep_outfolder(params.folders.rawcount)


log1 = Channel.create().subscribe { println "Log 1: $it" }

seq_samplesheet = Channel
    .fromPath("${folders.sequence_md}/${params.sequence_samplesheet_file}")
    .tap( log1 )
    .into {
        fastqc_samplesheet
        star_samplesheet
    }


module = {${param.module.command} ${param.module.${it} }}


//
// Discover input fastq files
//
fastq = Channel.fromPath("./100.fastq/*.fastq.gz")

// Spread the fastq channel across different analysis tracks
fastq.into {
    fastqc_input
    star_input
}

//
// Run Fastqc
// 
process runfastqc {
    name = 'fastqc run'
    cpus = 1    
    
    input:
	file fq from fastqc_input
    
    output:
        file "in_fastqc.html"
        file "in_fastqc.zip"
        file("${fq.name}.fastqc.tsv") into fastqc_summary_output

    script:
	template "run_fastqc.sh"
}


process mergefastqc {
    name = 'fastqc merge'
    cpus = 1

    input:
	file fqc_files from fastqc_summary_output.toList()
	file ssheet from fastqc_samplesheet
       
    output:
	file "fastqc_sample.tsv" into fastqc_sample_result
	file "fastqc_sequence.tsv" into fastqc_sequence_result

    script:
        template 'summarize_fastqc.py'
}

// ensure copies of fastqc output in the relevant folders
fastqc_sample_result.subscribe {
    it.mklink("${folders.sample_md}/fastqc.tsv", overwrite:true, hard:true) }
fastqc_sequence_result.subscribe {
    it.mklink("${folders.sequence_md}/fastqc.tsv", overwrite:true, hard:true) }


//
// STAR map
//

process runstar {
    
    name = "star map"
    cpus = 8
    
    input:
	file fq from star_input
    output:
	file "${fq.name}__Aligned.sortedByCoord.out.bam"
	file "${fq.name}__Aligned.sortedByCoord.out.bam.bai"
	file "${fq.name}__Chimeric.out.junction"
        file "${fq.name}__Chimeric.out.sam"
        file "${fq.name}__Log.final.out"
        file "${fq.name}__Log.progress.out"
        file "${fq.name}__SJ.out.tab"
        file "star.stdout"
        file "star.stderr"
        file "${fq.name}__counts.gz" into star_count_output
    file "${fq.name}__counts.summary"
    
    script:
	template "run_star.sh"        
}

process mergestarcount {
    name = 'star merge'
    cpus = 1

    input:
	file cnt_files from star_count_output.toList()
	file ssheet from star_samplesheet
       
    output:
	file "star_rawcount.tsv.gz" into star_rawcount_table
	file "star_seq_metadata.tsv" into star_seq_metadata
	file "star_sample_metadata.tsv" into star_sample_metadata
        stdout debug2
    
    script:
        template 'merge_star.py'
}

star_rawcount_table.subscribe {
    it.mklink("${folders.rawcount}/star_rawcount.tsv.gz", overwrite:true, hard:true) }
star_sample_metadata.subscribe {
    it.mklink("${folders.sample_md}/star.tsv", overwrite:true, hard:true) }
star_seq_metadata.subscribe {
    it.mklink("${folders.sequence_md}/star.tsv", overwrite:true, hard:true) }



debug2.subscribe { print "$it" }
