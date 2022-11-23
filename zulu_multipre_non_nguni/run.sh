#!/usr/bin/env bash


# Set this to somewhere where you want to put your data, or where
# someone else has already put it.  You'll want to change this
# if you're not on the CLSP grid.
data=../nchlt_corpora/nchlt_zulu

# base url for downloads.
# data_url=www.openslr.org/resources/12
# lm_url=www.openslr.org/resources/11

mfccdir=data/mfcc

lm_dir=data/lm

nj_train=8

stage=1

. ./cmd.sh
. ./path.sh
. parse_options.sh

# you might not want to do this for interactive shells.
set -e


if [ $stage -le 1 ]; then

  # download the data.  Note: we're using the 100 hour setup for
  # now; later in the script we'll download more and use it to train neural
  # nets.
  # for part in dev-clean test-clean dev-other test-other train-clean-100; do
  #   local/download_and_untar.sh $data $data_url $part
  # done

  # download the LM resources
  # local/download_lm.sh $lm_url data/local/lm

  echo "Stage 1: corpus and LM already present."

fi



if [ $stage -le 2 ]; then

  # format the data as Kaldi data directories
  # for part in dev-clean test-clean dev-other test-other train-clean-100; do
  #   # use underscore-separated names in data directories.
  #   local/data_prep.sh $data/LibriSpeech/$part data/$(echo $part | sed s/-/_/g)
  # done

  echo "Stage 2: data already formatted as Kaldi data directories."

fi

## Optional text corpus normalization and LM training
## These scripts are here primarily as a documentation of the process that has been
## used to build the LM. Most users of this recipe will NOT need/want to run
## this step. The pre-built language models and the pronunciation lexicon, as
## well as some intermediate data(e.g. the normalized text used for LM training),
## are available for download at http://www.openslr.org/11/
#local/lm/train_lm.sh $LM_CORPUS_ROOT \
#  data/local/lm/norm/tmp data/local/lm/norm/norm_texts data/local/lm

## Optional G2P training scripts.
## As the LM training scripts above, this script is intended primarily to
## document our G2P model creation process
#local/g2p/train_g2p.sh data/local/dict/cmudict data/local/lm



if [ $stage -le 3 ]; then

  # when the "--stage 3" option is used below we skip the G2P steps, and use the
  # lexicon we have already downloaded from openslr.org/11/

  # local/prepare_dict.sh --stage 3 --nj 30 --cmd "$train_cmd" \
  #  data/local/lm data/local/lm data/local/dict_nosp

  # utils/prepare_lang.sh data/local/dict_nosp \
  #  "<UNK>" data/local/lang_tmp_nosp data/lang_nosp

  echo "Stage 3: prepare_lang.sh already run."

  echo "Stage 3: executing local/format_lms.sh..."

  local/format_lms.sh --src-dir data/lang $lm_dir
  
fi

if [ $stage -le 4 ]; then

  # Create ConstArpaLm format language model for full 3-gram and 4-gram LMs
  
  echo "Stage 4: creating ConstArpaLm format language model..."
  
  utils/build_const_arpa_lm.sh data/lm/lm_tglarge.arpa.gz \
    data/lang data/lang_test_tglarge
  utils/build_const_arpa_lm.sh data/lm/lm_fglarge.arpa.gz \
    data/lang data/lang_test_fglarge

fi

if [ $stage -le 5 ]; then

  # # spread the mfccs over various machines, as this data-set is quite large.
  # if [[  $(hostname -f) ==  *.clsp.jhu.edu ]]; then
  #   mfcc=$(basename mfccdir) # in case was absolute pathname (unlikely), get basename.
  #   utils/create_split_dir.pl /export/b{02,11,12,13}/$USER/kaldi-data/egs/librispeech/s5/$mfcc/storage \
  #    $mfccdir/storage
  # fi
  
  echo "Stage 5: skip spreading the mfccs over various machines."

fi


if [ $stage -le 6 ]; then

  for part in dev train; do
      echo "Stage 6: extracting MFCCs..."
      steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj_train data/$part exp/make_mfcc/$part $mfccdir
      
      echo "Stage 6: computing updateCMVN stats..."
      steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
  done

fi

if [ $stage -le 7 ]; then

  # Make some small data subsets for early system-build stages.  Note, there are 29k
  # utterances in the train_clean_100 directory which has 100 hours of data.
  # For the monophone stages we select the shortest utterances, which should make it
  # easier to align the data from a flat start.

  echo "Stage 7: making 2000 utterance subset..."
  utils/subset_data_dir.sh --shortest data/train 2000 data/train_2kshort
  utils/subset_data_dir.sh data/train 5000 data/train_5k
  utils/subset_data_dir.sh data/train 10000 data/train_10k

fi

if [ $stage -le 8 ]; then

  # train a monophone system

  echo "Stage 8: training monophone system..."
  steps/train_mono.sh --boost-silence 1.25 --nj $nj_train --cmd "$train_cmd" \
                      data/train_2kshort data/lang exp/mono

fi

if [ $stage -le 9 ]; then


  echo "Stage 9: computing training alignments using the monophone model..."

  steps/align_si.sh --boost-silence 1.25 --nj $nj_train --cmd "$train_cmd" \
                    data/train_5k data/lang exp/mono exp/mono_ali_5k

  echo "Stage 9: training a triphone model with MFCC + delta + delta-delta features..."
  
  # train a first delta + delta-delta triphone system on a subset of 5000 utterances
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
                        2000 10000 data/train_5k data/lang exp/mono_ali_5k exp/tri1

fi

if [ $stage -le 10 ]; then

  echo "Stage 10: computing the training alignments using the triphone model..."

  steps/align_si.sh --nj $nj_train --cmd "$train_cmd" \
                    data/train_10k data/lang exp/tri1 exp/tri1_ali_10k

  echo "Stage 10: training a triphone model with LDA and MLLT feature transforms..."

  # train an LDA+MLLT system.
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
                          --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
                          data/train_10k data/lang exp/tri1_ali_10k exp/tri2b

fi

if [ $stage -le 11 ]; then

  echo "Stage 11: computing the training alignments using the new triphone model..."

  # Align a 10k utts subset using the tri2b model
  steps/align_si.sh  --nj $nj_train --cmd "$train_cmd" --use-graphs true \
                     data/train_10k data/lang exp/tri2b exp/tri2b_ali_10k

  echo "Stage 11: training a triphone model with SAT..."

  # Train tri3b, which is LDA+MLLT+SAT on 10k utts
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
                     data/train_10k data/lang exp/tri2b_ali_10k exp/tri3b

fi

if [ $stage -le 12 ]; then

  echo "Stage 12: computing the training alignments over the whole training dataset using the new triphone model..."

  # align the entire train_clean_100 subset using the tri3b model
  steps/align_fmllr.sh --nj $nj_train --cmd "$train_cmd" \
    data/train data/lang \
    exp/tri3b exp/tri3b_ali_all

  echo "Stage 12: training a triphone model on LDA+MLLT+SAT system over the whole training dataset..."

  # train another LDA+MLLT+SAT system on the entire 100 hour subset
  steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
                      data/train data/lang \
                      exp/tri3b_ali_all exp/tri4b

fi

if [ $stage -le 13 ]; then

  echo "Stage 13: computing the pronunciation and silence probabilities from training data..."

  # Now we compute the pronunciation and silence probabilities from training data,
  # and re-create the lang directory.
  steps/get_prons.sh --cmd "$train_cmd" \
                     data/train data/lang exp/tri4b

  utils/dict_dir_add_pronprobs.sh --max-normalize true \
                                  data/local/lang \
                                  exp/tri4b/pron_counts_nowb.txt exp/tri4b/sil_counts_nowb.txt \
                                  exp/tri4b/pron_bigram_counts_nowb.txt data/local/lang_prons

  echo "Stage 13: creating new lang directory..."

  utils/prepare_lang.sh data/local/lang_prons \
                        "<unk>" data/local/lang_tmp data/lang_update
  
  echo "Stage 13: building a new ConstArpa LM..."
   
  local/format_lms.sh --src-dir data/lang_update $lm_dir

  utils/build_const_arpa_lm.sh \
    data/lm/lm_tglarge.arpa.gz data/lang_update data/lang_test_tglarge
  
  utils/build_const_arpa_lm.sh \
    data/lm/lm_fglarge.arpa.gz data/lang_update data/lang_test_fglarge

fi

if [ $stage -le 14 ] && false; then

echo "Stage 14: can skip."

  # # This stage is for nnet2 training on 100 hours; we're commenting it out
  # # as it's deprecated.
  # # align train_clean_100 using the tri4b model
  # steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
  #   data/train_clean_100 data/lang exp/tri4b exp/tri4b_ali_clean_100

  # # This nnet2 training script is deprecated.
  # local/nnet2/run_5a_clean_100.sh

fi

if [ $stage -le 15 ]; then

echo "Stage 15: can skip."

  # local/download_and_untar.sh $data $data_url train-clean-360

  # # now add the "clean-360" subset to the mix ...
  # local/data_prep.sh \
  #   $data/LibriSpeech/train-clean-360 data/train_clean_360
  # steps/make_mfcc.sh --cmd "$train_cmd" --nj 40 data/train_clean_360 \
  #                    exp/make_mfcc/train_clean_360 $mfccdir
  # steps/compute_cmvn_stats.sh \
  #   data/train_clean_360 exp/make_mfcc/train_clean_360 $mfccdir

  # # ... and then combine the two sets into a 460 hour one
  # utils/combine_data.sh \
  #   data/train_clean_460 data/train_clean_100 data/train_clean_360

fi

if [ $stage -le 16 ]; then

echo "Stage 16: computing the training alignments using the last SAT model and new L.fst..."

  # align the new, combined set, using the tri4b model
  steps/align_fmllr.sh --nj $nj_train --cmd "$train_cmd" \
                       data/train data/lang_update exp/tri4b exp/tri4b_ali_all

  # # create a larger SAT model, trained on the 460 hours of data.
  # steps/train_sat.sh  --cmd "$train_cmd" 5000 100000 \
  #                     data/train_clean_460 data/lang exp/tri4b_ali_clean_460 exp/tri5b

fi


# The following command trains an nnet3 model on the 460 hour setup.  This
# is deprecated now.
## train a NN model on the 460 hour set
#local/nnet2/run_6a_clean_460.sh

if [ $stage -le 17 ]; then

echo "Stage 17: can skip."

  # # prepare the remaining 500 hours of data
  # local/download_and_untar.sh $data $data_url train-other-500

  # # prepare the 500 hour subset.
  # local/data_prep.sh \
  #   $data/LibriSpeech/train-other-500 data/train_other_500
  # steps/make_mfcc.sh --cmd "$train_cmd" --nj 40 data/train_other_500 \
  #                    exp/make_mfcc/train_other_500 $mfccdir
  # steps/compute_cmvn_stats.sh \
  #   data/train_other_500 exp/make_mfcc/train_other_500 $mfccdir

  # # combine all the data
  # utils/combine_data.sh \
  #   data/train_960 data/train_clean_460 data/train_other_500

fi

if [ $stage -le 18 ]; then

  # steps/align_fmllr.sh --nj 40 --cmd "$train_cmd" \
  #                      data/train_960 data/lang exp/tri5b exp/tri5b_ali_960

  # # train a SAT model on the 960 hour mixed data.  Use the train_quick.sh script
  # # as it is faster.
  # steps/train_quick.sh --cmd "$train_cmd" \
  #                      7000 150000 data/train_960 data/lang exp/tri5b_ali_960 exp/tri6b

  echo "Stage 18: creating the graph (HCLG.fst model) with the small trigram LM...."
  # decode using the tri4b model
  utils/mkgraph.sh data/lang_test_tgsmall \
                   exp/tri4b exp/tri4b/graph_tgsmall

  # for test in test_clean test_other dev_clean dev_other; do
  #     steps/decode_fmllr.sh --nj 20 --cmd "$decode_cmd" \
  #                           exp/tri6b/graph_tgsmall data/$test exp/tri6b/decode_tgsmall_$test
  #     steps/lmrescore.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tgmed} \
  #                        data/$test exp/tri6b/decode_{tgsmall,tgmed}_$test
  #     steps/lmrescore_const_arpa.sh \
  #       --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
  #       data/$test exp/tri6b/decode_{tgsmall,tglarge}_$test
  #     steps/lmrescore_const_arpa.sh \
  #       --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
  #       data/$test exp/tri6b/decode_{tgsmall,fglarge}_$test
  # done

  # for test in test dev; do

  #   echo "Stage 18: decoding test set using the SAT model and the small trigram LM..."
  #   steps/decode_fmllr.sh --nj 4 --cmd "$decode_cmd" \
  #                         exp/tri4b/graph_tgsmall data/$test exp/tri4b/decode_tgsmall_$test
    
  #   echo "Stage 18: rescoring decoded lattice with medium trigram LM..."  
  #   steps/lmrescore.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tgmed} \
  #                       data/$test exp/tri4b/decode_{tgsmall,tgmed}_$test

  #   echo "Stage 18: rescoring decoded lattice with large ConstArpa LM..."  
  #   steps/lmrescore_const_arpa.sh \
  #     --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
  #     data/$test exp/tri4b/decode_{tgsmall,tglarge}_$test
    
  #   echo "Stage 18: rescoring decoded lattice with large ConstArpa LM..."  
  #   steps/lmrescore_const_arpa.sh \
  #     --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
  #     data/$test exp/tri4b/decode_{tgsmall,fglarge}_$test\
  
  # done

  echo "Stage 18: decoding dev set using the SAT model and the small trigram LM..."
  steps/decode_fmllr.sh --nj $nj_train --cmd "$decode_cmd" \
                        exp/tri4b/graph_tgsmall data/dev exp/tri4b/decode_tgsmall_dev
  
  echo "Stage 18: rescoring decoded lattice with medium trigram LM..."  
  steps/lmrescore.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tgmed} \
                      data/dev exp/tri4b/decode_{tgsmall,tgmed}_dev

  echo "Stage 18: rescoring decoded lattice with large ConstArpa LM..."  
  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
    data/dev exp/tri4b/decode_{tgsmall,tglarge}_dev
  
  echo "Stage 18: rescoring decoded lattice with large ConstArpa LM..."  
  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
    data/dev exp/tri4b/decode_{tgsmall,fglarge}_dev\

fi


# if [ $stage -le 19 ]; then

#   # this does some data-cleaning. The cleaned data should be useful when we add
#   # the neural net and chain systems.  (although actually it was pretty clean already.)
#   local/run_cleanup_segmentation.sh

# fi

# steps/cleanup/debug_lexicon.sh --remove-stress true  --nj 200 --cmd "$train_cmd" data/train_clean_100 \
#    data/lang exp/tri6b data/local/dict/lexicon.txt exp/debug_lexicon_100h

# #Perform rescoring of tri6b be means of faster-rnnlm
# #Attention: with default settings requires 4 GB of memory per rescoring job, so commenting this out by default
# wait && local/run_rnnlm.sh \
#     --rnnlm-ver "faster-rnnlm" \
#     --rnnlm-options "-hidden 150 -direct 1000 -direct-order 5" \
#     --rnnlm-tag "h150-me5-1000" $data data/local/lm

# #Perform rescoring of tri6b be means of faster-rnnlm using Noise contrastive estimation
# #Note, that could be extremely slow without CUDA
# #We use smaller direct layer size so that it could be stored in GPU memory (~2Gb)
# #Suprisingly, bottleneck here is validation rather then learning
# #Therefore you can use smaller validation dataset to speed up training
# wait && local/run_rnnlm.sh \
#     --rnnlm-ver "faster-rnnlm" \
#     --rnnlm-options "-hidden 150 -direct 400 -direct-order 3 --nce 20" \
#     --rnnlm-tag "h150-me3-400-nce20" $data data/local/lm


# if [ $stage -le 20 ]; then

#   # train and test nnet3 tdnn models on the entire data with data-cleaning.
#   local/chain/run_tdnn.sh # set "--stage 11" if you have already run local/nnet3/run_tdnn.sh

# fi

# The nnet3 TDNN recipe:
# local/nnet3/run_tdnn.sh # set "--stage 11" if you have already run local/chain/run_tdnn.sh

# # train models on cleaned-up data
# # we've found that this isn't helpful-- see the comments in local/run_data_cleaning.sh
# local/run_data_cleaning.sh

# # The following is the current online-nnet2 recipe, with "multi-splice".
# local/online/run_nnet2_ms.sh

# # The following is the discriminative-training continuation of the above.
# local/online/run_nnet2_ms_disc.sh

# ## The following is an older version of the online-nnet2 recipe, without "multi-splice".  It's faster
# ## to train but slightly worse.
# # local/online/run_nnet2.sh
