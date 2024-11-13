#!/bin/bash -e
#SSchott
#Modified from install_colabbatch_linux.sh from YoshitakaMo @ https://github.com/YoshitakaMo/localcolabfold
type wget 2>/dev/null || { echo "wget is not installed. Please install it using apt or yum." ; exit 1 ; }

CURRENTPATH=`pwd`
ALPHAFOLD3DIR="${CURRENTPATH}/localalphafold3"

mkdir -p "${ALPHAFOLD3DIR}"
cd "${ALPHAFOLD3DIR}"
mkdir models
wget -q -P . https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash ./Miniforge3-Linux-x86_64.sh -b -p "${ALPHAFOLD3DIR}/conda"
rm Miniforge3-Linux-x86_64.sh

source "${ALPHAFOLD3DIR}/conda/etc/profile.d/conda.sh"
export PATH="${ALPHAFOLD3DIR}/conda/condabin:${PATH}"
conda update -n base conda -y
conda create -p "$ALPHAFOLD3DIR/alphafold3-conda" -c conda-forge \
    git python=3.11 -y
conda activate "$ALPHAFOLD3DIR/alphafold3-conda"

# get hmmer
mkdir hmmer_build hmmer ; \
    wget http://eddylab.org/software/hmmer/hmmer-3.4.tar.gz --directory-prefix hmmer_build ; \
    (cd hmmer_build && tar zxf hmmer-3.4.tar.gz && rm hmmer-3.4.tar.gz) ; \
    (cd hmmer_build/hmmer-3.4 && ./configure --prefix ${ALPHAFOLD3DIR}/hmmer) ; \
    (cd hmmer_build/hmmer-3.4 && make -j8) ; \
    (cd hmmer_build/hmmer-3.4 && make install) ; \
    (cd hmmer_build/hmmer-3.4/easel && make install) ; \
    rm -R hmmer_build

# clone repo
git clone https://github.com/google-deepmind/alphafold3.git
cd alphafold3
# install dependencies with pip
pip3 install -r dev-requirements.txt
pip3 install --no-deps .
build_data

echo "-----------------------------------------"
echo "Installation of AlphaFold 3 environment finished."
echo ""
echo "YOU NEED TO GET THE WEIGHTS FROM GOOGLE YOURSELF, AND ACCEPT THEIR LICENSE AGREEMENT!"
echo "Afterwards you can decompress them under $ALPHAFOLD3DIR/models"

echo "You need to get the databases to run the data pipeline. Consider using the script provided by DeepMind fetch_databases.py. See the README about this"
echo "Depending where you installed the databases, you can run the pipeline by using a command similar to (no GPU need, but access to DB!):"
echo "${ALPHAFOLD3DIR}/alphafold3-conda/bin/python $(realpath run_alphafold.py) \ "
echo "--jackhmmer_binary_path $ALPHAFOLD3DIR/hmmer/bin/jackhmmer \ " 
echo "--db_dir \$DBPATH \ "
echo "--output_dir \$YOUROUTPUTPATH \ "
echo "--json_path \$YOURINPUT \ "
echo "--model_dir $ALPHAFOLD3DIR/models/ \ "
echo "--hmmalign_binary_path $ALPHAFOLD3DIR/hmmer/bin/hmmalign \ "
echo "--hmmbuild_binary_path $ALPHAFOLD3DIR/hmmer/bin/hmmbuild \ "
echo "--hmmsearch_binary_path $ALPHAFOLD3DIR/hmmer/bin/hmmsearch \ "
echo "--norun_inference "
echo ""
echo "This will generate a json file in your \$YOUROUTPUTPATH, which is the input for the inference step!"
echo "Either copy this file, or use a different \$YOUROUTPUTPATH in the inference step to avoid overwriting!"
echo "Inference step:"
echo "${ALPHAFOLD3DIR}/alphafold3-conda/bin/python $(realpath run_alphafold.py) \ "
echo "--jackhmmer_binary_path $ALPHAFOLD3DIR/hmmer/bin/jackhmmer \ " 
echo "--db_dir \$DBPATH \ "
echo "--output_dir \$YOUROUTPUTPATH \ "
echo "--json_path \$YOURINPUT \ "
echo "--model_dir $ALPHAFOLD3DIR/models/ \ "
echo "--hmmalign_binary_path $ALPHAFOLD3DIR/hmmer/bin/hmmalign \ "
echo "--hmmbuild_binary_path $ALPHAFOLD3DIR/hmmer/bin/hmmbuild \ "
echo "--hmmsearch_binary_path $ALPHAFOLD3DIR/hmmer/bin/hmmsearch \ "
echo "--norun_data_pipeline "
