#!/usr/bin/env bash

# set -e
set -e -o pipefail

# Acoustic Model Parameters
numLeavesTri=2500
numGaussTri=30000
numLeavesMLLT=3500
numGaussMLLT=50000
numLeavesSAT=4000 
numGaussSAT=60000 
numGaussUBM=750   
numLeavesSGMM=4500     
numGaussSGMM=70000

# configs for 'chain'
stage=0
decode_nj=8
train_stage=-10
get_egs_stage=-10

# configs for transfer learning

src_mdl=/home/wakawaka/kaldi/egs/nchlt/multi_other/exp/chain/tdnn_1d_sp/final.mdl
# src_mdl=../../wsj/s5/exp/chain/tdnn1d_sp/final.mdl # Input chain model
                                                   # trained on source dataset (wsj).
                                                   # This model is transfered to the target domain.

src_mfcc_config=/home/wakawaka/kaldi/egs/nchlt/multi_other/conf/mfcc_hires.conf
# src_mfcc_config=../../wsj/s5/conf/mfcc_hires.conf # mfcc config used to extract higher dim
                                                  # mfcc features for ivector and DNN training
                                                  # in the source domain.

src_ivec_extractor_dir=/home/wakawaka/kaldi/egs/nchlt/multi_other/exp/nnet3/extractor                                                 
# src_ivec_extractor_dir=  # Source ivector extractor dir used to extract ivector for
                         # source data. The ivector for target data is extracted using this extractor.
                         # It should be nonempty, if ivector is used in the source model training.

# src_tree_dir=/home/wakawaka/kaldi/egs/nchlt/multi_nguni/exp/chain/tree_sp
# src_tree_dir=../../wsj/s5/exp/chain/tree_a_sp/tree_a_sp # chain tree-dir for src data;
                                         # the alignment in target domain is
                                         # converted using src-tree

primary_lr_factor=0.25 # The learning-rate factor for transferred layers from source
                       # model. e.g. if 0, the paramters transferred from source model
                       # are fixed.
                       # The learning-rate factor for new added layers is 1.0.


train_set=train
gmm=tri4b
nnet3_affix=

# The rest are configs specific to this script.  Most of the parameters
# are just hardcoded at this level, in the commands below.
affix=1d
tree_affix=

decode_iter=

# TDNN options
frames_per_eg=150,110,100
remove_egs=true
common_egs_dir=
xent_regularize=0.1
dropout_schedule='0,0@0.20,0.5@0.50,0'

test_online_decoding=true  # if true, it will run the last decoding stage.

# End configuration section.
echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi


required_files="$src_mfcc_config $src_mdl"
use_ivector=false
ivector_dim=$(nnet3-am-info --print-args=false $src_mdl | grep "ivector-dim" | cut -d" " -f2)
if [ -z $ivector_dim ]; then ivector_dim=0 ; fi

if [ ! -z $src_ivec_extractor_dir ]; then
  if [ $ivector_dim -eq 0 ]; then
    echo "$0: Source ivector extractor dir '$src_ivec_extractor_dir' is specified "
    echo "but ivector is not used in training the source model '$src_mdl'."
  else
    required_files="$required_files $src_ivec_extractor_dir/final.dubm $src_ivec_extractor_dir/final.mat $src_ivec_extractor_dir/final.ie"
    use_ivector=true
  fi
else
  if [ $ivector_dim -gt 0 ]; then
    echo "$0: ivector is used in training the source model '$src_mdl' but no "
    echo " --src-ivec-extractor-dir option as ivector dir for source model is specified." && exit 1;
  fi
fi

for f in $required_files; do
  if [ ! -f $f ]; then
    echo "$0: no such file $f." && exit 1;
  fi
done


# The iVector-extraction and feature-dumping parts are the same as the standard
# nnet3 setup, and you can skip them by setting "--stage 11" if you have already
# run those things.

echo -e "iVectors already extracted.\n"
# echo -e "extracting iVectors..."
# local/nnet3/run_ivector_transfer.sh --stage $stage \
#                                     --train-set $train_set \
#                                     --ivector-dim $ivector_dim \
#                                     --nnet3-affix "$nnet3_affix"  \
#                                     --mfcc-config $src_mfcc_config \
#                                     --extractor $src_ivec_extractor_dir \
#                                     --gmm $gmm \
#                                     --num-threads-ubm 4 || exit 1;

gmm_dir=exp/$gmm
ali_dir=exp/${gmm}_ali_${train_set}_sp
tree_dir=exp/chain${nnet3_affix}/tree_sp${tree_affix:+_$tree_affix}
lang=data/lang_chain
lat_dir=exp/chain${nnet3_affix}/${gmm}_${train_set}_sp_lats
dir=exp/chain${nnet3_affix}/tdnn${affix:+_$affix}_sp
train_data_dir=data/${train_set}_sp_hires
lores_train_data_dir=data/${train_set}_sp
train_ivector_dir=exp/nnet3${nnet3_affix}/ivectors_${train_set}_sp_hires

# if we are using the speed-perturbed data we need to generate
# alignments for it.

for f in $gmm_dir/final.mdl $train_data_dir/feats.scp $train_ivector_dir/ivector_online.scp \
    $lores_train_data_dir/feats.scp $ali_dir/ali.1.gz; do
  [ ! -f $f ] && echo "$0: expected file $f to exist" && exit 1
done

# Please take this as a reference on how to specify all the options of
# local/chain/run_chain_common.sh

echo -e "run_chain_common.sh already executed.\n"
# echo -e "executing run_chain_common.sh...\n"

# local/chain/run_chain_common.sh --stage $stage \
#                                 --gmm-dir $gmm_dir \
#                                 --ali-dir $ali_dir \
#                                 --lores-train-data-dir ${lores_train_data_dir} \
#                                 --lang $lang \
#                                 --lat-dir $lat_dir \
#                                 --num-leaves 7000 \
#                                 --tree-dir $tree_dir || exit 1;

# echo -e "run_chain_common.sh returned.\n"


if [ $stage -le 1 ]; then

  echo -e "\nStage 1 completed. \n"

#   echo -e "\nStage 1\n"

#   echo "$0: Create neural net configs using the xconfig parser for";
#   echo " generating new layers.";
  
#   num_targets=$(tree-info $tree_dir/tree | grep num-pdfs | awk '{print $2}')
  
#   learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)
  
#   affine_opts="l2-regularize=0.008 dropout-proportion=0.0 dropout-per-dim=true dropout-per-dim-continuous=true"
#   tdnnf_opts="l2-regularize=0.008 dropout-proportion=0.0 bypass-scale=0.75"
#   linear_opts="l2-regularize=0.008 orthonormal-constraint=-1.0"
#   prefinal_opts="l2-regularize=0.008"
#   output_opts="l2-regularize=0.002"

#   mkdir -p $dir
#   mkdir -p $dir/configs
  
#   cat <<EOF > $dir/configs/network.xconfig
#   prefinal-layer name=prefinal-chain input=prefinal-l $prefinal_opts big-dim=1536 small-dim=256
#   output-layer name=output include-log-softmax=false dim=$num_targets $output_opts

#   prefinal-layer name=prefinal-xent input=prefinal-l $prefinal_opts big-dim=1536 small-dim=256
#   output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts

# EOF
#   steps/nnet3/xconfig_to_configs.py --existing-model $src_mdl \
#     --xconfig-file  $dir/configs/network.xconfig  \
#     --config-dir $dir/configs/

#   # Set the learning-rate-factor to be primary_lr_factor for transferred layers "
#   # and adding new layers to them.
#   $train_cmd $dir/log/generate_input_mdl.log \
#     nnet3-copy --edits="set-learning-rate-factor name=* learning-rate-factor=$primary_lr_factor; set-learning-rate-factor name=output* learning-rate-factor=1.0" $src_mdl - \| \
#       nnet3-init --srand=1 - $dir/configs/final.config $dir/input.raw  || exit 1;

fi

if [ $stage -le 2 ]; then

  # echo -e "\nStage 2 completed.\n"

  echo -e "\nStage 2\n"

  steps/nnet3/chain/train.py --stage $train_stage \
    --use-gpu=wait \
    --cmd "$decode_cmd" \
    --trainer.input-model $dir/input.raw \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.0 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --egs.dir "$common_egs_dir" \
    --egs.stage $get_egs_stage \
    --egs.opts "--frames-overlap-per-eg 0 --constrained false" \
    --egs.chunk-width $frames_per_eg \
    --trainer.dropout-schedule $dropout_schedule \
    --trainer.add-option="--optimization.memory-compression-level=2" \
    --trainer.num-chunk-per-minibatch 64 \
    --trainer.frames-per-iter 2500000 \
    --trainer.num-epochs 1 \
    --trainer.optimization.num-jobs-initial 8 \
    --trainer.optimization.num-jobs-final 8 \
    --trainer.optimization.initial-effective-lrate 0.00015 \
    --trainer.optimization.final-effective-lrate 0.000015 \
    --trainer.max-param-change 2.0 \
    --cleanup.remove-egs $remove_egs \
    --feat-dir $train_data_dir \
    --tree-dir $tree_dir \
    --lat-dir $lat_dir \
    --dir $dir  || exit 1;

fi

# graph_dir=$dir/graph_tgsmall

# if [ $stage -le 3 ]; then
#   # Note: it might appear that this $lang directory is mismatched, and it is as
#   # far as the 'topo' is concerned, but this script doesn't read the 'topo' from
#   # the lang directory.
#   utils/mkgraph.sh --self-loop-scale 1.0 --remove-oov data/lang_test_tgsmall $dir $graph_dir
# fi

# iter_opts=
# if [ ! -z $decode_iter ]; then
#   iter_opts=" --iter $decode_iter "
# fi

# if [ $stage -le 4 ]; then
#   rm $dir/.error 2>/dev/null || true
#   for decode_set in test_clean test dev_clean dev_other; do
#       (
#       steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
#           --nj $decode_nj --cmd "$decode_cmd" $iter_opts \
#           --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${decode_set}_hires \
#           $graph_dir data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter}_tgsmall || exit 1
#       steps/lmrescore.sh --cmd "$decode_cmd" --self-loop-scale 1.0 data/lang_test_{tgsmall,tgmed} \
#           data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter}_{tgsmall,tgmed} || exit 1
#       steps/lmrescore_const_arpa.sh \
#           --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
#           data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter}_{tgsmall,tglarge} || exit 1
#       steps/lmrescore_const_arpa.sh \
#           --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
#           data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter}_{tgsmall,fglarge} || exit 1
#       ) || touch $dir/.error &
#   done
#   wait
#   if [ -f $dir/.error ]; then
#     echo "$0: something went wrong in decoding"
#     exit 1
#   fi
# fi

# if $test_online_decoding && [ $stage -le 5 ]; then
#   # note: if the features change (e.g. you add pitch features), you will have to
#   # change the options of the following command line.
#   steps/online/nnet3/prepare_online_decoding.sh \
#        --mfcc-config conf/mfcc_hires.conf \
#        $lang exp/nnet3${nnet3_affix}/extractor $dir ${dir}_online

#   rm $dir/.error 2>/dev/null || true
#   for data in test_clean test_other dev_clean dev_other; do
#     (
#       nspk=$(wc -l <data/${data}_hires/spk2utt)
#       # note: we just give it "data/${data}" as it only uses the wav.scp, the
#       # feature type does not matter.
#       steps/online/nnet3/decode.sh \
#           --acwt 1.0 --post-decode-acwt 10.0 \
#           --nj $nspk --cmd "$decode_cmd" \
#           $graph_dir data/${data} ${dir}_online/decode_${data}_tgsmall || exit 1

#     ) || touch $dir/.error &
#   done
#   wait
#   if [ -f $dir/.error ]; then
#     echo "$0: something went wrong in decoding"
#     exit 1
#   fi
# fi


exit 0;
