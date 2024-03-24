#!/bin/bash
source /sl_folder.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD08_DIR=${BASE_DIR}/08-voltaML

mkdir -p ${SD08_DIR}
mkdir -p /config/outputs/08-voltaML

if [ ! -f "$SD08_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/08.txt" "$SD08_DIR/parameters.txt"
fi

if [ ! -d "${SD08_DIR}/voltaML-fast-stable-diffusion" ]; then
    cd "${SD08_DIR}" && git clone https://github.com/VoltaML/voltaML-fast-stable-diffusion.git
fi

# check if remote is ahead of local
# https://stackoverflow.com/a/25109122/1469797
cd ${SD08_DIR}/voltaML-fast-stable-diffusion
if [ "$CLEAN_ENV" != "true" ] && [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ]; then
    echo "Local branch up-to-date, keeping existing venv"
    else
        if [ "$CLEAN_ENV" = "true" ]; then
        echo "Forced wiping venv for clean packages install"
        else
        echo "Remote branch is ahead. Wiping venv for clean packages install"
        fi
    export active_clean=1
#    git reset --hard HEAD
    git pull -X ours
fi

#clean conda env if needed
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    rm -rf ${SD08_DIR}/env
    rm -rf ${SD08_DIR}/voltaML-fast-stable-diffusion/venv
    export active_clean=0
    echo "Done!"
    echo -e "-------------------------------------\n"
fi

#create conda env if missing
if [ ! -d ${SD08_DIR}/env ]; then
    conda create -p ${SD08_DIR}/env -y
fi

#activate conda env and install packages
source activate ${SD08_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip=22.3.1 gcc gxx --solver=libmamba -y
conda install pytorch torchvision torchaudio -c pytorch --solver=libmamba -y

#create python venv if missing
if [ ! -d ${SD08_DIR}/voltaML-fast-stable-diffusion/venv ]; then
    cd ${SD08_DIR}/voltaML-fast-stable-diffusion
    python -m venv venv
fi

cd ${SD08_DIR}/voltaML-fast-stable-diffusion
source venv/bin/activate
#pip install --upgrade pip
pip install onnxruntime-gpu

for fichier in ${SD08_DIR}/voltaML-fast-stable-diffusion/requirements/*.txt; do
    echo "installation of requirements"
    pip install -r $fichier
done

#move models to common folders and create symlinks
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data models ${BASE_DIR}/models stable-diffusion
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data lora ${BASE_DIR}/models lora
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data vae ${BASE_DIR}/models vae
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data textual-inversion ${BASE_DIR}/models embeddings
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data upscaler ${BASE_DIR}/models upscale
sl_folder ${SD08_DIR}/voltaML-fast-stable-diffusion/data outputs /config/outputs 08-voltaML

cd ${SD08_DIR}/voltaML-fast-stable-diffusion
# launch Volta ML
CMD="python3 main.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD08_DIR}/parameters.txt"
eval $CMD
