# ATLAS - Deep Learning Assert Statements
ATLAS, our neural machine translation based approach, automatically learns how to generate assert statements for a given test and focal method.
ATLAS provides instructions, datasets, and a deep learning infrastructure (based on [seq2seq](https://google.github.io/seq2seq/)) that aims at learning how to *translate* a test and focal method into an appropriate and accurate assert statement.
Our approach consists of a Recurrent Neural Network (RNN) Encoder-Decoder model, which is trained to learn from a set of test methods mined from GitHub repositories. All examples pertain to the use of the [Junit4](https://github.com/junit-team/junit4) framework. 

### Training Data
Procuring the dataset for ATLAS was done through the use of [spoon](https://search.maven.org/remote_content?g=fr.inria.gforge.spoon&a=spoon-core&v=LATEST&c=jar-with-dependencies), which creates a model of the source code in order to access particular elemments such as methods.
We use spoon to build models for other 9K open source projects on GitHub and extract test methods using the annotation @Test. The data is then filtered and formatted in preparation for ATLAS to learn from.
This data can be found in the dataset folder. The dataset as a whole is separated into a training, testing and evaluation set for both the raw and abstracted data.

### Vocabulary
The model requires a vocabulary from which it can choose tokens when generating a prediction. This vocabulary is generated using a python script. This script can be located in the Source_Code/bin/tools folder.

### Example
Once the data and the vocabulary has been generated the script train_test.sh can be ran to generate a new model using seq2seq. 
For your convienence, both the raw and abstracted model that were generated using this script is included in the Models folder.
```
mkdir -p ../models/raw_model/
./train_test.sh ../dataset/raw/training/ 300000 ../models/raw_model/ assertConfig
```

## Inference
The script `inference.sh` performs inference on a trained model. The inference is performed using Beam Search. The following figure shows an example of Beam Search with beam width *k* = 3.

<p align="center">
  <img src="https://drive.google.com/uc?export=view&id=1Nh5AtRLq9EX4u_H9phYVvhF6MYEtdgmb"/>
</p>

The values of *k* can be specified in the script where the `beam_widths` array is initialized (line #20).
```
./inference.sh <dataset_path> <model_path>
```
Arguments:
- `dataset_path` : path to the dataset containing the folders: train, eval, test (e.g., see `dataset` folder). Only the data in `test` is used during inference;
- `model_path` : path of the trained model;

### Example
```
./inference.sh ../dataset/raw/testing/ ../models/raw_model/
```

### Abstract Dataset
This dataset is generated using a tokenization technique. This process requires the use of [javalang](https://github.com/c2nes/javalang), a python library to tokenize java methods.
We use the types denoted by the javalang package and assign numerical values to tokens of the same type, depending on the order in which they are encountered. 
For example, the first method call encountered within a java method would be given the token 'METHOD_0'. The token describes the type and the numerical representation describes the number of times that particular type of token, within the java method, has been encountered.
Therefore, we can reuse tokens between different java methods since the numerical representations would reset after each java method. This significantly reduces our vocabulary for learning. 


