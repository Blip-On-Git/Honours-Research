import xml.etree.ElementTree as ET
import sys

# base_path="/home/wakawaka/kaldi/egs/nchlt/nchlt_corpora/"

corpus = sys.argv[1]
base_path = sys.argv[2]

train_tree = ET.parse(f'{corpus}.trn.xml')
test_tree = ET.parse(f'{corpus}.tst.xml')

aux_tree = ET.parse(f'{corpus}.aux1.xml')

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
aux_corpus = aux_tree.getroot()

train_wav = open("wav_train.scp", "w")
dev_wav = open("wav_dev.scp", "w")
test_wav = open("wav_test.scp", "w")


trans_spk_pairs = []
ids = []

for speaker in train_corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]
        relative_path = recording.attrib['audio']
        full_path = base_path + relative_path

        transcription = recording[0].text
        pair = (id.split('_')[2],transcription)
        trans_spk_pairs.append(pair)

        ids.append(id)

        if id in train_list:
            train_wav.write(id + ' ' + full_path +'\n')
        elif id in dev_list:
            dev_wav.write(id + ' ' + full_path +'\n')
        elif id in test_list:
            test_wav.write(id + ' ' + full_path +'\n')


for speaker in test_corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0]
        relative_path = recording.attrib['audio']
        full_path = base_path + relative_path

        transcription = recording[0].text
        pair = (id.split('_')[2],transcription)
        trans_spk_pairs.append(pair)

        ids.append(id)

        if id in train_list:
            train_wav.write(id + ' ' + full_path +'\n')
        elif id in dev_list:
            dev_wav.write(id + ' ' + full_path +'\n')
        elif id in test_list:
            test_wav.write(id + ' ' + full_path +'\n')


duplicate_count = 0
num_aux = 0
total_aux = 0

for speaker in aux_corpus:
    for recording in speaker:

        id = recording.attrib['audio'].split('/')[-1].split('.')[0].replace("nchltAux1_nbl","nchlt_nbl")
        
        relative_path = recording.attrib['audio'].replace("nchltAux1/nbl","nchlt_nbl_aux1")
        full_path = base_path + relative_path

        dur = float(recording.attrib['duration'])

        transcription = recording[0].text

        if id in ids:
            print("duplicate id")

        pair = (id.split('_')[2],transcription)

        if pair not in trans_spk_pairs:
            train_wav.write(id + ' ' + full_path +'\n')
            num_aux += 1
            total_aux += dur
        
        else:
            duplicate_count +=1

print(f"excluded {duplicate_count} 'speaker-transcription' duplicates from aux corpus")
print(f"added {num_aux} items ({round(total_aux/60/60,2)}hrs) from aux corpus")


train_list_f.close()
dev_list_f.close()
test_list_f.close()
train_wav.close()
dev_wav.close()
test_wav .close()