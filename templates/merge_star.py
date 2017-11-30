#!/usr/bin/env python

import pandas as pd
import numpy as np

print("Loading Samplesheet ${ssheet}")
ssheet = pd.read_csv("${ssheet}", sep="\\t", names="file sample".split(), index_col=0)

dd = []
for f in "${cnt_files}".split():
    c1 = pd.read_csv(f, sep="\\t", comment="#", index_col=0)
    dd.append(c1.iloc[:,5])

dd = pd.concat(dd, axis=1).T
dd.index = dd.index.str.replace("__Aligned.sortedByCoord.out.bam", "")

seqmd = pd.DataFrame(dict(
    star_mapped_reads = dd.sum(1),
    star_std_reads = dd.std(1),
    star_mean_reads = dd.mean(1),
    star_median_reads = dd.median(1),
    star_q90_reads = dd.quantile(q=0.9, axis=1),
    star_q95_reads = dd.quantile(q=0.95, axis=1),
    star_q99_reads = dd.quantile(q=0.99, axis=1),
    star_nonzero = (dd > 0).sum(1),
    star_over10 = (dd > 10).sum(1),
    star_over100 = (dd > 100).sum(1),
))

seqmd.to_csv('star_seq_metadata.tsv', sep="\t")



dd['sample'] = list(ssheet.loc[dd.index]['sample'])
dd = dd.groupby('sample').sum()

dd.to_csv('star_rawcount.tsv.gz', sep="\\t", compression='gzip')


seqmd = pd.DataFrame(dict(
    star_mapped_reads = dd.sum(1),
    star_std_reads = dd.std(1),
    star_mean_reads = dd.mean(1),
    star_median_reads = dd.median(1),
    star_q90_reads = dd.quantile(q=0.9, axis=1),
    star_q95_reads = dd.quantile(q=0.95, axis=1),
    star_q99_reads = dd.quantile(q=0.99, axis=1),
    star_nonzero = (dd > 0).sum(1),
    star_over10 = (dd > 10).sum(1),
    star_over100 = (dd > 100).sum(1),
))

seqmd.to_csv('star_sample_metadata.tsv', sep="\\t")
