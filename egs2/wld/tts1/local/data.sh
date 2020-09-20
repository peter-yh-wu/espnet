#!/bin/bash

set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

stage=-1
stop_stage=2

log "$0 $*"
. utils/parse_options.sh

if [ $# -ne 0 ]; then
    log "Error: No positional arguments are required."
    exit 2
fi

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;
. ./db.sh || exit 1;

if [ -z "${WLD}" ]; then
   log "Fill the value of 'JSUT' of db.sh"
   exit 1
fi
db_root=${WLD}

train_set=tr_no_dev
train_dev=dev
recog_set=eval1

if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
    log "stage -1: Data Download (Skipping)"
fi

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    log "stage 0: local/data_prep.sh"

    # check directory existence
    [ ! -e data/train ] && mkdir -p data/train

    # set filenames
    scp=data/train/wav.scp
    utt2spk=data/train/utt2spk
    spk2utt=data/train/spk2utt
    text=data/train/text
    segments=data/train/segments

    # check file existence
    [ -e ${scp} ] && rm ${scp}
    [ -e ${utt2spk} ] && rm ${utt2spk}
    [ -e ${text} ] && rm ${text}
    [ -e ${segments} ] && rm ${segments}

    # make scp, utt2spk, and spk2utt
    find ${db_root}/HNDSKV/aligned/wav -name "*.wav" -follow | sort | while read -r filename; do
        id="$(basename ${filename} .wav)"
        echo "${id} ${filename}" >> ${scp}
        echo "${id} wld" >> ${utt2spk}
    done
    utils/utt2spk_to_spk2utt.pl ${utt2spk} > ${spk2utt}

    # make text
    while read -r l; do
        l2=${l:2:-19}
        echo ${l2//'"'/""} >> ${text}
    done < ${db_root}/HNDSKV/aligned/etc/txt.done.data

    # make segments
    cat ${db_root}/HNDSKV/aligned/etc/segments >> ${segments}

fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    log "stage 2: utils/subset_data_dir.sh"
    # make evaluation and development sets
    utils/subset_data_dir.sh --last data/train 200 data/deveval
    utils/subset_data_dir.sh --last data/deveval 100 data/${recog_set}
    utils/subset_data_dir.sh --first data/deveval 100 data/${train_dev}
    n=$(( $(wc -l < data/train/wav.scp) - 200 ))
    utils/subset_data_dir.sh --first data/train ${n} data/${train_set}
fi

log "Successfully finished. [elapsed=${SECONDS}s]"
