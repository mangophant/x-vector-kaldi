# SR using x-vector on Aishell

### Environment

- WSL LTS 20.04
- kaldi
- python 3

### Dataset

- [Aishell](http://www.openslr.org/33/)(170h, 400 speakers)

### Configuration

- Configure path of kaldi in `path.sh`:

```shell
export KALDI_ROOT=xxx/kaldi # kaldi root
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C
```

- Configure train cmd in `cmd.sh`:

```shell
export train_cmd="run.pl -mem 4G"
```

- Configure softlinks:

```shell
ln -snf $KALDI_ROOT/egs/sre08/v1/sid sid
ln -snf $KALDI_ROOT/egs/wsj/s5/steps steps
ln -snf $KALDI_ROOT/egs/wsj/s5/utils utils
```

### Train Step by Step

```shell
sudo ./stage0_prepare_train_data.sh
sudo ./stage1_make_mfcc_vad.sh
sudo ./stage2_filter_feature.sh
sudo ./stage3_train_x_vector.sh
# TODO
# extract x-vector, train plda and score
```

### Reference

[kaldi](http://kaldi-asr.org/) | [Aishell](https://arxiv.org/abs/1709.05522) | [x-vector](https://ieeexplore.ieee.org/document/8461375)

 The following datasets can be used in data augmentation:

- [MUSAN](http://www.openslr.org/17)
- [RIR_NOISES](http://www.openslr.org/28)