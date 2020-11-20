. ./path.sh
. ./cmd.sh

nnet_dir=exp/xvector_nnet_la
sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd" --nj 20 $nnet_dir data/train exp/xvectors_train

$train_cmd exp/xvectors_train/log/compute_mean.log ivector-mean scp:exp/xvectors_train/xvector.scp exp/xvectors_train/mean.vec

lda_dim=150
$train_cmd exp/xvectors_train/log/lda.log ivector-compute-lda --total-covariance-factor=0.0 --dim=$lda_dim "ark:ivector-subtract-global-mean scp:exp/xvectors_train/xvector.scp ark:- |" ark:data/train/utt2spk exp/xvectors_train/transform.mat || echo "LDA failed";

$train_cmd exp/xvectors_train/log/plda.log ivector-compute-plda ark:data/train/spk2utt "ark:ivector-subtract-global-mean scp:exp/xvectors_train/xvector.scp ark:- | transform-vec exp/xvectors_train/transform.mat ark:- ark:- | ivector-normalize-length ark:-  ark:- |" exp/xvectors_train/plda || echo "PLDA failed";
