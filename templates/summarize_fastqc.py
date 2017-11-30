#!/usr/bin/env python

import pandas as pd
import numpy as np

print("Loading Samplesheet ${ssheet}")

ssheet = pd.read_csv("${ssheet}", sep="\\t", names="file sample".split(), index_col=0)

dd = []
for f in "${fqc_files}".split():
   dd.append(pd.read_csv(f, sep="\\t", names="fq name val".split()))

dd = pd.concat(dd).pivot(index='fq', columns='name', values='val')

numcols = "Total_Sequences Sequences_flagged_as_poor_quality 1 10 20 30 5".split()
for nc in numcols:
    dd[nc] = pd.to_numeric(dd[nc])

# write sequence fastqc file
dd.to_csv("fastqc_sequence.tsv", sep="\\t")

#merge across samples
dd['sample'] = list(ssheet.loc[dd.index]["sample"])

aggfunc = dict(zip('1 5 10 20 30'.split(), [np.mean] * 5))
aggfunc['Total_Sequences'] = np.sum
aggfunc['Sequences_flagged_as_poor_quality'] = np.sum
aggfunc['Encoding'] = lambda x: x.iloc[0]

dd = dd.groupby(by='sample').agg(aggfunc)
dd.to_csv("fastqc_sample.tsv", sep="\\t")
