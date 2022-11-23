import xml.etree.ElementTree as ET
import sys

# xml_name = sys.argv[1]

# tree = ET.parse(xml_name + '.xml')
# corpus = tree.getroot()

# dataset_type = xml_name.split('.')[1]
# text_name = "text_" + dataset_type
# f = open(text_name, "w")

lang = sys.argv[1]
corpus = sys.argv[2]

train_tree = ET.parse(f'{corpus}.trn.xml')
test_tree = ET.parse(f'{corpus}.tst.xml')

train_list_f = open(f"{corpus}.trn.lst","r")
dev_list_f = open(f"{corpus}.dev.lst","r")
test_list_f = open(f"{corpus}.tst.lst","r")

train_list = train_list_f.readlines()
dev_list = dev_list_f.readlines()
test_list = test_list_f.readlines()


for  i in range(len(train_list)):
    if "\n" in train_list[i]:
        train_list[i] = train_list[i].replace("\n","")

for  i in range(len(dev_list)):
    if "\n" in dev_list[i]:
        dev_list[i] = dev_list[i].replace("\n","")

for  i in range(len(test_list)):
    if "\n" in test_list[i]:
        test_list[i] = test_list[i].replace("\n","")


train_corpus = train_tree.getroot()
test_corpus = test_tree.getroot()

train_text = open(f"{lang}_text_train", "w")
dev_text = open(f"{lang}_text_dev", "w")
test_text = open(f"{lang}_text_test", "w")


for speaker in train_corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]
        transcription = recording[0].text

        if id in train_list:
            train_text.write(id + ' ' + transcription+'\n')
        elif id in dev_list:
            dev_text.write(id + ' ' + transcription+'\n')
        elif id in test_list:
            test_text.write(id + ' ' + transcription+'\n')


for speaker in test_corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]
        transcription = recording[0].text

        if id in train_list:
            train_text.write(id + ' ' + transcription+'\n')
        elif id in dev_list:
            dev_text.write(id + ' ' + transcription+'\n')
        elif id in test_list:
            test_text.write(id + ' ' + transcription+'\n')


train_list_f.close()
dev_list_f.close()
test_list_f.close()
train_text.close()
dev_text.close()
test_text.close()



