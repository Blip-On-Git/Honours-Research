import xml.etree.ElementTree as ET
import sys

corpus = sys.argv[1]

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

train_utt2spk = open("utt2spk_train", "w")
dev_utt2spk = open("utt2spk_dev", "w")
test_utt2spk = open("utt2spk_test", "w")


for speaker in train_corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]
        
        recording_name = recording.attrib['audio'].split('/')[-1].split('.')[0]
        utt_id = recording_name
        spk_id = recording_name.split('_')[2]

        if id in train_list:
            train_utt2spk.write(utt_id + ' ' + spk_id+'\n')
        elif id in dev_list:
            dev_utt2spk.write(utt_id + ' ' + spk_id+'\n')
        elif id in test_list:
            test_utt2spk.write(utt_id + ' ' + spk_id+'\n')


for speaker in test_corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]

        recording_name = recording.attrib['audio'].split('/')[-1].split('.')[0]
        utt_id = recording_name
        spk_id = recording_name.split('_')[2]

        if id in train_list:
            train_utt2spk.write(utt_id + ' ' + spk_id+'\n')
        elif id in dev_list:
            dev_utt2spk.write(utt_id + ' ' + spk_id+'\n')
        elif id in test_list:
            test_utt2spk.write(utt_id + ' ' + spk_id+'\n')

        

train_list_f.close()
dev_list_f.close()
test_list_f.close()
train_utt2spk.close()
dev_utt2spk.close()
test_utt2spk.close()



