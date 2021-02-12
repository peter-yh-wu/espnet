#!/bin/bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

lid=false # whether to use language id as additional label

train_set="train"
train_dev="dev"
test_set="test"

nlsyms_txt=data/local/nlsyms.txt
asr_config=conf/train_asr.yaml
inference_config=conf/decode_asr.yaml

ngpu=1

./asr.sh \
    --stage 1 \
    --stop_stage 100 \
    --ngpu ${ngpu} \
    --nj 80 \
    --inference_nj 256 \
    --use_lm false \
    --token_type bpe \
    --nbpe 1000 \
    --feats_type raw \
    --asr_config "${asr_config}" \
    --inference_config "${inference_config}" \
    --train_set "${train_set}" \
    --valid_set "${train_dev}" \
    --test_sets "${test_set}" \
    --nlsyms_txt "${nlsyms_txt}" \
    --lm_train_text "data/${train_set}/text" \
    --local_score_opts "--score_lang_id ${lid}" "$@"
