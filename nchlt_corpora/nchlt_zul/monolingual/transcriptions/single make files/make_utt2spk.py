import xml.etree.ElementTree as ET
import sys

xml_name = sys.argv[1]

tree = ET.parse(xml_name + '.xml')
corpus = tree.getroot()

dataset_type = xml_name.split('.')[1]
utt2spk_name = "utt2spk_" + dataset_type
f = open(utt2spk_name, "w")

for speaker in corpus:
    for recording in speaker:

        recording_name = recording.attrib['audio'].split('/')[-1].split('.')[0]
        utt_id = recording_name
        spk_id = recording_name.split('_')[2]
        f.write(utt_id + ' ' + spk_id+'\n')

f.close() 



