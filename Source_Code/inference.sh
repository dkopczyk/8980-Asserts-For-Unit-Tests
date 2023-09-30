: ${2?"usage: ${0} <DATA_DIR> <MODEL_DIR>"}

#Inputs
DATA_DIR="${1}";
MODEL_DIR="${2}";

#Setting environment variables
export DATA_DIR=${DATA_DIR}
export VOCAB_SOURCE=${DATA_DIR}/Vocabulary/vocab.buggy.txt
export VOCAB_TARGET=${DATA_DIR}/Vocabulary/vocab.fixed.txt
export TEST_SOURCES=${DATA_DIR}/test/testMethods.txt
export TEST_TARGETS=${DATA_DIR}/test/assertLines.txt
export MODEL_DIR=${MODEL_DIR}

PRED_SCRIPTS="predictions/"


echo "------------------- TESTING BEAM SEARCH ------------------------" 

beam_widths=("5" "10" "15" "20" "25" "30" "35" "40" "45" "50" "100" "200")

for beam_width in ${beam_widths[*]}; do
	
	echo "Beam width: $beam_width"
	
	export PRED_DIR=${MODEL_DIR}/pred_$beam_width
	mkdir -p ${PRED_DIR}
	
	SECONDS=0;
	
python3 -m bin.infer \
  --tasks "
    - class: DecodeText
	REMOVE NEXT TWO LINES TO REMOVE COPY MECHANISM
	  params:
        unk_replace: True"\
    - class: DumpBeams
      params:
        file: ${PRED_DIR}/beams.npz" \
  --model_dir $MODEL_DIR \
  --model_params "
    inference.beam_search.beam_width: $beam_width" \
  --input_pipeline "
    class: ParallelTextInputPipeline
    params:
      source_files:
        - $TEST_SOURCES" \
  > ${PRED_DIR}/predictions.beam.txt

	elapsed=$SECONDS;
	echo "---------- TIME REPORT ----------" 
	echo "Beam width: $beam_width"
	echo "Total seconds: $elapsed"

	total=`wc -l ${TEST_TARGETS}| awk '{print $1}'`
	asserts=$(($total * $beam_width))
	avg="$(echo "scale=6; $elapsed / $asserts" | bc)"
	avg_assert="$(echo "scale=6; $elapsed / $total" | bc)"
	
	echo "Total asserts without beams: $total"
	echo "Total asserts with beams: $asserts" 
	echo "Avg asserts generated per sec: $avg"
	echo "Avg assert resolved per sec: $avg_assert"
	echo "---------------------------------"
	


#Run prediction classification
total=`wc -l ${TEST_TARGETS}| awk '{print $1}'`
echo "Test Set: $total"
cp $VOCAB_TARGET ${PRED_DIR}/
python3 $PRED_SCRIPTS/beamPredictions.py ${PRED_DIR}
output=$(python3 $PRED_SCRIPTS/beam_prediction_classifier.py ${TEST_SOURCES} ${TEST_TARGETS} "${PRED_DIR}/predictions.beam.mul.txt" 2>&1)
perf=`awk '{print $1}' <<< "$output"`
changed=`awk '{print $2}' <<< "$output"`
perf_perc="$(echo "scale=2; $perf * 100 / $total" | bc)"

echo "---------- PREDICTIONS REPORT ----------"
echo "Beam width: $beam_width"
echo "Perf: $perf ($perf_perc%)"
echo "Pot : $changed"
echo "--------------------------------------"	
	
done