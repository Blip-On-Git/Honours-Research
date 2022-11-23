# !/usr/bin/env bash

base_path="/home/wakawaka/kaldi/egs/nchlt/nchlt_corpora/"

python3 make_wav_scp.py nchlt_zul.trn "$base_path"
python3 make_wav_scp.py nchlt_zul.tst "$base_path"