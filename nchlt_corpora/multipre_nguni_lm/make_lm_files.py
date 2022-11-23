

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
for line in lexicon_lines:
    # if line.split(" ")[0]!="<eps>":
    vocab.write(line.split(" ")[0]+"\n")

text.close()
lexicon.close()
