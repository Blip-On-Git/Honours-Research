

vocab = open("vocab", "w")
train_txt = open("train.txt", "w")

text = open("text","r")
lexicon = open("lexicon.txt","r")

text_lines  = text.readlines()
lexicon_lines = lexicon.readlines()


for line in text_lines:

    line_text = ' '.join(line.split()[1:])

    train_txt.write(line_text+"\n")


vocab.write("</s>\n")
vocab.write("<s>\n")

vocab_set = set()
vocab_set.add("<s>")
vocab_set.add("</s>")

for line in lexicon_lines:
    # if line.split(" ")[0]!="<eps>":
    if not(line.split(" ")[0] in vocab_set):
        vocab.write(line.split(" ")[0]+"\n")
        vocab_set.add(line.split(" ")[0])

text.close()
lexicon.close()
