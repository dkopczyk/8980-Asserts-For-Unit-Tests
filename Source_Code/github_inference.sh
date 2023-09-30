: ${2?"usage: ${0} <DATA_DIR> <MODEL_DIR>"}

#Inputs
DATA_DIR="${1}";
MODEL_DIR="${2}";

#Setting environment variables
export DATA_DIR=${DATA_DIR}
export VOCAB_SOURCE=${DATA_DIR}/Vocabulary/vocab.testMethods.txt
export VOCAB_TARGET=${DATA_DIR}/Vocabulary/vocab.assertLines.txt
export TEST_SOURCES=${DATA_DIR}/InputMethods.txt
export MODEL_DIR=${MODEL_DIR}

PRED_SCRIPTS="predictions/"


echo "------------------- TESTING BEAM SEARCH ------------------------" 

beam_widths=("5")

for beam_width in ${beam_widths[*]}; do
	
	echo "Beam width: $beam_width"
	
	export PRED_DIR=${MODEL_DIR}/Github_pred_$beam_width
	mkdir -p ${PRED_DIR}
	
	SECONDS=0;
	
python3 -m bin.infer \
  --tasks "
    - class: DecodeText
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

	echo "---------------------------------"
	


#Run prediction classification
echo "Test Set: $total"
cp $VOCAB_TARGET ${PRED_DIR}/
python3 $PRED_SCRIPTS/beamPredictions.py ${PRED_DIR}
	
done
