: ${4?"usage: ${0} <DATA_DIR> <TRAIN_STEPS> <MODEL_DIR> <CONFIG>"}

#Inputs
DATA_DIR="${1}";
TRAIN_STEPS="${2}";
MODEL_DIR="${3}";
CONFIG="${4}";

#Setting environment variables

export DATA_DIR=${DATA_DIR}
export VOCAB_SOURCE=${DATA_DIR}/Vocabulary/vocab.testMethods.txt
export VOCAB_TARGET=${DATA_DIR}/Vocabulary/vocab.assertLines.txt
export TRAIN_SOURCES=${DATA_DIR}/Training/testMethods.txt
export TRAIN_TARGETS=${DATA_DIR}/Training/assertLines.txt
export DEV_SOURCES=${DATA_DIR}/Eval/testMethods.txt
export DEV_TARGETS=${DATA_DIR}/Eval/assertLines.txt
export TEST_SOURCES=${DATA_DIR}/Testing/testMethods.txt
export TEST_TARGETS=${DATA_DIR}/Testing/assertLines.txt

PRED_SCRIPTS="predictions/"

CHECKPOINT_STEPS=10000
EVAL_STEPS=10000
MAX_CHECKPOINT=3

export TRAIN_STEPS=${TRAIN_STEPS}
export CHECKPOINT_STEPS=${CHECKPOINT_STEPS}
export EVAL_STEPS=${EVAL_STEPS}
export MAX_CHECKPOINT=${MAX_CHECKPOINT}

#Generate vocabulary
#bin/tools/generate_vocab.py < ${TRAIN_SOURCES} > ${VOCAB_SOURCE}
#bin/tools/generate_vocab.py < ${TRAIN_TARGETS} > ${VOCAB_TARGET}

#Create output model dir
export MODEL_DIR=${MODEL_DIR}
mkdir -p $MODEL_DIR

python3 -m bin.train \
  --config_paths="
      ./configs/$CONFIG.yml,
      ./example_configs/train_seq2seq_optimized.yml,
      ./example_configs/text_metrics.yml" \
  --model_params "
      vocab_source: $VOCAB_SOURCE
      vocab_target: $VOCAB_TARGET" \
  --input_pipeline_train "
    class: ParallelTextInputPipeline
    params:
      source_files:
        - $TRAIN_SOURCES
      target_files:
        - $TRAIN_TARGETS" \
  --input_pipeline_dev "
    class: ParallelTextInputPipeline
    params:
       source_files:
        - $DEV_SOURCES
       target_files:
        - $DEV_TARGETS" \
  --batch_size 32 \
  --train_steps $TRAIN_STEPS \
  --output_dir $MODEL_DIR \
  --save_checkpoints_steps $CHECKPOINT_STEPS \
  --eval_every_n_steps $EVAL_STEPS \
  --keep_checkpoint_max $MAX_CHECKPOINT

echo "------------------- TESTING GREEDY ------------------------" 
#Testing

export PRED_DIR=${MODEL_DIR}/pred
mkdir -p ${PRED_DIR}

python3 -m bin.infer \
  --tasks "
    - class: DecodeText
//REMOVE NEXT TWO LINES TO REMOVE COPY MECHANISM
	  params:
	    unk_replace: True"\
  --model_dir $MODEL_DIR \
  --input_pipeline "
    class: ParallelTextInputPipeline
    params:
      source_files:
        - $TEST_SOURCES" \
  >  ${PRED_DIR}/predictions.txt


echo "------------------- BLEU ------------------------" 

echo "prediction vs assertLines"  
./bin/tools/multi-bleu.perl ${TEST_TARGETS} < ${PRED_DIR}/predictions.txt  

echo "------------------- CLASSIFICATION ------------------------"   

total=`wc -l ${TEST_TARGETS}| awk '{print $1}'`
echo "Test Set: $total"

echo "Predictions"
output=$(python3 $PRED_SCRIPTS/prediction_classifier.py ${TEST_TARGETS} "${PRED_DIR}/predictions.txt" 2>&1)
perf=`awk '{print $1}' <<< "$output"`
imperf=`awk '{print $2}' <<< "$output"`
perf_perc="$(echo "scale=2; $perf * 100 / $total" | bc)"

echo "Perf: $perf ($perf_perc%)"
echo "Pot : $imperf"

./inference.sh $DATA_DIR $MODEL_DIR

