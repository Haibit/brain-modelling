#!/bin/bash

# # Test
# DIR=output/std-s03-10/aal-coarse-19-outer-nocer-plus2/lf-sources-ch12-trials100-samplesall-normeachchannel-envyes-for-filter
# NAME=2017-04-14-MCMTLOCCD_TWL4-T20-C12-P11-lambda0.9900-gamma1.000e-05-pdc-dynamic-diag-ds4-seed-*-thresh0.00-0.0000-0.0195

# ./make-pdf-from-images.sh --dir=$DIR --name=$NAME

DATA=(
    # LEFT 
    "output/std-s05-10/aal-coarse-19-outer-nocer-hemileft-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P5-lambda0.9900-gamma1.000e-03-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-hemileft-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P5-lambda0.9900-gamma1.000e-04-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"
    
    "output/std-s05-10/aal-coarse-19-outer-nocer-hemileft-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P5-lambda0.9900-gamma1.000e-05-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-hemileft-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P5-lambda0.9900-gamma1.000e-06-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-hemileft-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-*-lambda0.9900-*-p1-removed-pdc-dynamic-diag-f2048-41-ds4-adjacency-idx192-768-0.0000-0.0024"

    # RIGHT
    "output/std-s05-10/aal-coarse-19-outer-nocer-hemiright-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P5-lambda0.9900-gamma1.000e-03-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-hemiright-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P7-lambda0.9900-gamma1.000e-04-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"
    
    "output/std-s05-10/aal-coarse-19-outer-nocer-hemiright-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P5-lambda0.9900-gamma1.000e-05-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-hemiright-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-C7-P5-lambda0.9900-gamma1.000e-06-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-hemiright-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-17-MCMTLOCCD_TWL4-T100-*-lambda0.9900-*-p1-removed-pdc-dynamic-diag-f2048-41-ds4-adjacency-idx192-768-0.0000-0.0024"

    # BOTH
    "output/std-s05-10/aal-coarse-19-outer-nocer-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-27-MCMTLOCCD_TWL4-T100-C13-P5-lambda0.9900-gamma1.000e-03-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-27-MCMTLOCCD_TWL4-T100-C13-P5-lambda0.9900-gamma1.000e-04-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"
    
    "output/std-s05-10/aal-coarse-19-outer-nocer-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-27-MCMTLOCCD_TWL4-T100-C13-P3-lambda0.9900-gamma1.000e-05-p1-removed-pdc-dynamic-diag-f2048-41-ds4-seed-*-opnone-thresh0.00-0.0000-0.0049"

    "output/std-s05-10/aal-coarse-19-outer-nocer-audr2-v1r2/lf-data-trialsall-samplesall-normeachchannel-envyes-prependflipdata"
    "2017-07-27-MCMTLOCCD_TWL4-T100-*-lambda0.9900-*-p1-removed-pdc-dynamic-diag-f2048-41-ds4-adjacency-idx192-768-0.0000-0.0024"
    )

index=0
len=${#DATA[@]}
while [ $index -lt "$len" ]
do
    # get DIR and NAME
    DIR=${DATA[$index]}
    NAME=${DATA[$index+1]}
    echo "DIR: " $DIR
    echo "NAME: " $NAME

    ./make-pdf-from-images.sh --dir=$DIR --name=$NAME

    # Next pair
    index=$(($index+2))
done
