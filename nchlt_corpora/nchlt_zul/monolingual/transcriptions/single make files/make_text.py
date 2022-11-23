import xml.etree.ElementTree as ET
import sys

xml_name = sys.argv[1]

tree = ET.parse(xml_name + '.xml')
corpus = tree.getroot()

dataset_type = xml_name.split('.')[1]
text_name = "text_" + dataset_type
f = open(text_name, "w")

for speaker in corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]
        transcription = recording[0].text
        f.write(id + ' ' + transcription+'\n')

f.close() 



