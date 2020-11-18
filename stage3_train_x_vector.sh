stage=0
train_stage=0
use_gpu=false
remove_egs=false

data=data/train_no_sil
nnet_dir=exp/xvector_nnet_la
egs_dir=exp/xvector_nnet_la/egs

. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh

num_pdfs=$(awk '{print $2}' $data/utt2spk | sort | uniq -c | wc -l)

if [ $stage -le 4 ]; then
	echo "$0: Getting neural network training egs"
	# dump egs
	if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $egs_dir/storage ]; then
		utils/create_split_dir.pl /home/cmgg/dev/SR/xvector-$(date +'%m_%d_%H_%M')/$egs_dir/storage $egs_dir/storage
	fi
	sid/nnet3/xvector/get_egs.sh --cmd "$train_cmd" \
		--nj 8 \
		--stage 0 \
		--frames-per-iter 1000000000 \
		--frames-per-iter-diagnostic 100000 \
		--min-frames-per-chunk 100 \
		--max-frames-per-chunk 200 \
		--num-diagnostic-archives 3 \
		--num-repeats 35 \
		"$data" $egs_dir
fi

if [ $stage -le 5 ]; then
	echo "$0: Creating nn configs using xconfig parser"
	num_targets=$(wc -w $egs_dir/pdf2num | awk '{print $1}')
	feat_dim=$(cat $egs_dir/info/feat_dim)
	
	max_chunk_size=10000
	min_chunk_size=25
	mkdir -p $nnet_dir/configs
	cat <<EOF > $nnet_dir/configs/network.xconfig
	
	input dim=${feat_dim} name=input
	relu-batchnorm-layer name=tdnn1 input=Append(-2,-1,0,1,2) dim=512
	relu-batchnorm-layer name=tdnn2 input=Append(-2,0,2) dim=512
	relu-batchnorm-layer name=tdnn3 input=Append(-3,0,3) dim=512
	relu-batchnorm-layer name=tdnn4 dim=512
	relu-batchnorm-layer name=tdnn5 dim=1500
	stats-layer name=stats config=mean+stddev(0:1:1:${max_chunk_size})
    relu-batchnorm-layer name=tdnn6 dim=512 input=stats
	relu-batchnorm-layer name=tdnn7 dim=512
	output-layer name=output include-log-softmax=true dim=${num_targets}
EOF
	steps/nnet3/xconfig_to_configs.py \
		--xconfig-file $nnet_dir/configs/network.xconfig \
		--config-dir $nnet_dir/configs/
	cp $nnet_dir/configs/final.config $nnet_dir/nnet.config
	
	echo "output-node name=output input=tdnn6.affine" > $nnet_dir/extract.config
	echo "$max_chunk_size" > $nnet_dir/max_chunk_size
	echo "$min_chunk_size" > $nnet_dir/min_chunk_size
fi

dropout_schedule='0,0@0.20,0.1@0.50,0'
srand=123
if [ $stage -le 6 ]; then
	steps/nnet3/train_raw_dnn.py --stage=$train_stage \
		--cmd="$train_cmd" \
		--trainer.optimization.proportional-shrink 10 \
		--trainer.optimization.momentum=0.5 \
		--trainer.optimization.num-jobs-initial=1 \
		--trainer.optimization.num-jobs-final=1 \
		--trainer.optimization.initial-effective-lrate=0.001 \
		--trainer.optimization.final-effective-lrate=0.0001 \
		--trainer.optimization.minibatch-size=64 \
		--trainer.srand=$srand \
		--trainer.max-param-change=2 \
		--trainer.num-epochs=80 \
		--trainer.dropout-schedule="$dropout_schedule" \
		--trainer.shuffle-buffer-size=1000 \
		--egs.frames-per-eg=1 \
		--egs.dir="$egs_dir" \
		--cleanup.remove-egs $remove_egs \
		--cleanup.preserve-model-interval=10 \
		--use-gpu=$use_gpu \
		--dir=$nnet_dir  || exit 1;
fi

exit 0;
