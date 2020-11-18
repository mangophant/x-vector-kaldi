. ./path.sh
set -e
data=/home/cmgg/corpora/data_aishell
local/aishell_data_prep.sh $data/wav $data/transcript
