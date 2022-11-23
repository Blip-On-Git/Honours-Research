# Honours-Research

## Evaluating the use of multilingual pre-training to improve speech recognition for low-resource South African languages

This repository contains the results and a limited set of the Kaldi files for each ASR system. The folders are named and structured based on normal Kaldi project structure. Word Error Rate results for each system can be found by following the general tree below.

```
Kaldi Project
|
├── data: this contains all data for the models, excluding the audio files.
│   ├── dev
│   │   ├── text_dev
│   │   ├── utt2spk_dev
│   │   └── wav_dev.scp
│   ├── lm
│   ├── local
│   │   └── lang
│   │       ├── lexicon.txt
│   │       ├── nonsilence_phones.txt
│   │       ├── optional_silence.txt
│   │       └── silence_phones.txt
│   ├── test
│   │   ├── text_test
│   │   ├── utt2spk_test
│   │   └── wav_test.scp
│   └── train
│       ├── text_train
│       ├── utt2spk_train
│       └── wav_train.scp
├── exp
│   ├── chain
│   │   └── tdnn_1d_sp
│   │       ├── decode_dev_tgsmall: THIS CONTAINS THE VALIDATION WORD ERROR RATES
│   │       │   ├── scoring_kaldi
│   │       │   │   |
│   │       │   │   └── best_wer:   the best validation WER - this is what was reported
│   │       │   │
|   |       |   └── other validation word error rate files
│   │       │   
│   │       └── decode_test_tgsmall: THIS CONTAINS THE TEST WORD ERROR RATES
│   │           ├── scoring_kaldi
│   │           │   └──  best_wer:  the best test WER - this is what was reported
│   │           │
|   |           └── other test word error rate files
│   └── nnet3
|
└── scripts and other execution files for constructing, training, and evaluating system
```