. ./cmd.sh
. ./path.sh

# delete silent frames with no voice
local/nnet3/xvector/prepare_feats_for_egs.sh --nj 40 --cmd "$train_cmd" data/train data/train_no_sil exp/train_no_sil
utils/fix_data_dir.sh data/train_no_sil

# delete the audio that has less than 200 frames
min_len=200
awk -v min_len=${min_len} '$2 > min_len {print $1, $2}' data/train_no_sil/utt2num_frames > data/train_no_sil/utt2num_frames.new
mv data/train_no_sil/utt2num_frames.new data/train_no_sil/utt2num_frames
utils/filter_scp.pl data/train_no_sil/utt2num_frames data/train_no_sil/utt2spk > data/train_no_sil/utt2spk.new
mv data/train_no_sil/utt2spk.new data/train_no_sil/utt2spk
utils/fix_data_dir.sh data/train_no_sil

# delete speakers that have less than 8 utterances
min_num_utts=0
awk '{print $1, NF-1}' data/train_no_sil/spk2utt > data/train_no_sil/spk2num
awk -v min_num_utts=${min_num_utts} '$2 >= min_num_utts {print $1, $2}' data/train_no_sil/spk2num | utils/filter_scp.pl - data/train_no_sil/spk2utt > data/train_no_sil/spk2utt.new
mv data/train_no_sil/spk2utt.new data/train_no_sil/spk2utt
utils/spk2utt_to_utt2spk.pl data/train_no_sil/spk2utt > data/train_no_sil/utt2spk
utils/filter_scp.pl data/train_no_sil/utt2spk data/train_no_sil/utt2num_frames > data/train_no_sil/utt2num_frames.new
mv data/train_no_sil/utt2num_frames.new data/train_no_sil/utt2num_frames
utils/fix_data_dir.sh data/train_no_sil
