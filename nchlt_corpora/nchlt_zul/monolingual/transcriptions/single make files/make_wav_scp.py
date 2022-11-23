import xml.etree.ElementTree as ET
import sys

xml_name = sys.argv[1]
base_path = sys.argv[2]

# base_path="/home/wakawaka/kaldi/egs/nchlt/nchlt_corpora/"


tree = ET.parse(xml_name + '.xml')
corpus = tree.getroot()

dataset_type = xml_name.split('.')[1]

wav_scp_name = "wav_" + dataset_type +".scp"
f = open(wav_scp_name, "w")

for speaker in corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]
        relative_path = recording.attrib['audio']
        full_path = base_path + relative_path 
        f.write(id + ' ' + full_path +'\n')

f.close() 