#!/bin/bash
set -e
set -x

# Create and activate virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    python -m venv venv
fi
source venv/Scripts/activate

# Upgrade pip
# python.exe -m pip install --upgrade pip

# Install requirements
# pip install -r requirements2.txt

# Download data if not already downloaded
if [ ! -d "ag_ckpt_vocab" ]; then
    gdown --folder https://bit.ly/alphageometry
fi
export DATA=ag_ckpt_vocab

# Clone repository if not already cloned
MELIAD_PATH=meliad_lib/meliad
if [ ! -d "$MELIAD_PATH" ]; then
    mkdir -p $MELIAD_PATH
    git clone https://github.com/google-research/meliad $MELIAD_PATH
fi

# Correct PYTHONPATH
export PYTHONPATH=$(pwd)/$MELIAD_PATH

# Set arguments
DDAR_ARGS=(
  --defs_file=$(pwd)/defs.txt \
  --rules_file=$(pwd)/rules.txt \
)

BATCH_SIZE=2
BEAM_SIZE=2
DEPTH=2

SEARCH_ARGS=(
  --beam_size=$BEAM_SIZE \
  --search_depth=$DEPTH \
)

LM_ARGS=(
  --ckpt_path=$DATA \
  --vocab_path=$DATA/geometry.757.model \
  --gin_search_paths=$MELIAD_PATH/transformer/configs \
  --gin_file=base_htrans.gin \
  --gin_file=size/medium_150M.gin \
  --gin_file=options/positions_t5.gin \
  --gin_file=options/lr_cosine_decay.gin \
  --gin_file=options/seq_1024_nocache.gin \
  --gin_file=geometry_150M_generate.gin \
  --gin_param=DecoderOnlyLanguageModelGenerate.output_token_losses=True \
  --gin_param=TransformerTaskConfig.batch_size=$BATCH_SIZE \
  --gin_param=TransformerTaskConfig.sequence_length=128 \
  --gin_param=Trainer.restore_state_variables=False \
)

echo $PYTHONPATH

# Run the main script
python -m alphageometry \
--alsologtostderr \
--problems_file=$(pwd)/examples.txt \
--problem_name=orthocenter \
--mode=alphageometry \
"${DDAR_ARGS[@]}" \
"${SEARCH_ARGS[@]}" \
"${LM_ARGS[@]}"