#!/usr/bin/env bash

# Copyright 2014 Vassil Panayotov
# Apache 2.0

echo "execute from egs root!"

. ./path.sh || exit 1
. ./cmd.sh || exit 1

stage=1

# LM pruning threshold for the 'small' trigram model
prune_thresh_small=0.0000003

# LM pruning threshold for the 'medium' trigram model
prune_thresh_medium=0.0000001


lm_dir=$1

vocab=$lm_dir/vocab
full_corpus=$lm_dir/train.txt


trigram_lm=$lm_dir/lm_tglarge.arpa.gz

if [ "$stage" -le 1 ]; then
  echo "Training a 3-gram LM ..."
  command -v ngram-count 1>/dev/null 2>&1 || { echo "Please install SRILM and set path.sh accordingly"; exit 1; }
  echo "This implementation assumes that you have a lot of free RAM(> 12GB) on your machine"
  echo "If that's not the case, consider something like: http://joshua-decoder.org/4.0/large-lms.html"
  ngram-count -order 3  -kndiscount -interpolate \
    -unk -map-unk "<unk>" -limit-vocab -vocab $vocab -text $full_corpus -lm $trigram_lm || exit 1
  du -h $trigram_lm
fi

trigram_pruned_small=$lm_dir/lm_tgsmall.arpa.gz

if [ "$stage" -le 1 ]; then
  echo "Creating a 'small' pruned 3-gram LM (threshold: $prune_thresh_small) ..."
  command -v ngram 1>/dev/null 2>&1 || { echo "Please install SRILM and set path.sh accordingly"; exit 1; }
  ngram -prune $prune_thresh_small -lm $trigram_lm -write-lm $trigram_pruned_small || exit 1
  du -h $trigram_pruned_small
fi

trigram_pruned_medium=$lm_dir/lm_tgmed.arpa.gz

if [ "$stage" -le 1 ]; then
  echo "Creating a 'medium' pruned 3-gram LM (threshold: $prune_thresh_medium) ..."
  command -v ngram 1>/dev/null 2>&1 || { echo "Please install SRILM and set path.sh accordingly"; exit 1; }
  ngram -prune $prune_thresh_medium -lm $trigram_lm -write-lm $trigram_pruned_medium || exit 1
  du -h $trigram_pruned_medium
fi

# fourgram_lm=$lm_dir/lm_fglarge.arpa.gz

# if [ "$stage" -le 1 ]; then
#   # This requires even more RAM than the 3-gram
#   echo "Training a 4-gram LM ..."
#   command -v ngram-count 1>/dev/null 2>&1 || { echo "Please install SRILM and set path.sh accordingly"; exit 1; }
#   ngram-count -order 4  -kndiscount -interpolate \
#     -unk -map-unk "<unk>" -limit-vocab -vocab $vocab -text $full_corpus -lm $fourgram_lm || exit 1
#   du -h $fourgram_lm
# fi

exit 0
