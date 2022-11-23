import sys

lang = sys.argv[1]

dict_name = sys.argv[2]
dictionary = open(dict_name+'.dict', 'r')
  
lexicon = open(f"{lang}_lexicon.txt", "w")
nonsilence_phones = open(f"{lang}_nonsilence_phones.txt", "w")
optional_silence = open("optional_silence.txt", "w")
silence_phones = open("silence_phones.txt", "w")

# add unknown word to lexicon
lexicon.write('<unk> sil\n')

# create silence phone files
silence_phones.write('sil')
optional_silence.write('sil')



# initialise set pf phones
nonsilence_phone_set = set()
  
# get next line from file
lines = dictionary.readlines()

# if the last line is empty, remove it
if lines[-1]=="":
    del lines[-1]    

# get the new last line and remove trailing newline character
last_line = ' '.join(lines[-1].split())


# loop through all lines
for line in lines:

    # make sure the line is not empty
    if line!="":
        

        # normalize the the whitespace in the string to only spaces
        line_space_delim = ' '.join(line.split())

        # split the line by spaces
        line_list = line_space_delim.split(' ')

        # check if forbidden word
        if line_list[0]=='</s>' or line_list[0]=='<s>':
            continue

        # get the list of phones in the pronunciation
        phones = line_list[1:]
        
        # check if pronunciation is non-silence
        if phones[0]!='sil':
            # add the phone to the phone set if it does not already exist
            for phone in phones:
                if phone not in nonsilence_phone_set:
                    nonsilence_phone_set.add(f"{lang}&{phone}")

        # add to lexicon.txt
        if line_list[0] not in ["SIL-ENCE","[s]"]:
            line_space_delim = line_space_delim.replace(" ",f" {lang}&")

        if line_space_delim!=last_line:
            lexicon.write(line_space_delim+'\n')
        else:
            lexicon.write(line_space_delim)

# convert phone set to list for ordering
nonsilence_phone_list = list(nonsilence_phone_set)
# get the last phone in the list
last_phone  = nonsilence_phone_list[-1]

# loop through all phones
for phone in nonsilence_phone_list:

    # add phone to non
    if phone!=last_phone:
        nonsilence_phones.write(phone+'\n')
    else:
        nonsilence_phones.write(phone)

lexicon.write('\n')
nonsilence_phones.write('\n')
optional_silence.write('\n')
silence_phones.write('\n')


lexicon.close()
nonsilence_phones.close()
optional_silence.close()
silence_phones.close()