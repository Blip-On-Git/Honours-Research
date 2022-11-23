export KALDI_ROOT="$(pwd)"/../../..

# export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/Program Files/ImageMagick-7.1.0-Q16-HDRI:/mnt/c/Windows/system32:/mnt/c/Windows:/mnt/c/Windows/System32/Wbem:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:/mnt/c/Windows/System32/OpenSSH/:/mnt/c/Program Files (x86)/NVIDIA Corporation/PhysX/Common:/mnt/c/Program Files/NVIDIA Corporation/NVIDIA NvDLISR:/mnt/c/Program Files/Git/cmd:/mnt/c/Users/talio/AppData/Local/Programs/Python/Python310/Scripts/:/mnt/c/Users/talio/AppData/Local/Programs/Python/Python310/:/mnt/c/Users/talio/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/talio/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Users/talio/AppData/Local/GitHubDesktop/bin:/mnt/c/Program Files/JetBrains/PyCharm 2022.2/bin:/snap/bin"

export PATH="$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH"
[ ! -f "$KALDI_ROOT"/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. "$KALDI_ROOT/tools/config/common_path.sh"

export LC_ALL=C

# we use this both in the (optional) LM training and the G2P-related scripts
PYTHON='python2.7'

### Below are the paths used by the optional parts of the recipe

# We only need the Festival stuff below for the optional text normalization(for LM-training) step
FEST_ROOT=tools/festival
NSW_PATH="${FEST_ROOT}/festival/bin:${FEST_ROOT}/nsw/bin"
export PATH="$PATH:$NSW_PATH"

# SRILM is needed for LM model building
SRILM_ROOT="$KALDI_ROOT/tools/srilm"
SRILM_PATH="$SRILM_ROOT/bin:$SRILM_ROOT/bin/i686-m64"
export PATH="$PATH:$SRILM_PATH"

# Sequitur G2P executable
sequitur="$KALDI_ROOT/tools/sequitur-g2p/g2p.py"
sequitur_path="$(dirname $sequitur)/lib/$PYTHON/site-packages"

# Directory under which the LM training corpus should be extracted
LM_CORPUS_ROOT=./lm-corpus
