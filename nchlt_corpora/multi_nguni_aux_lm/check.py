train_txt = open("train.txt", "r")

text_lines = train_txt.readlines()

for line in text_lines:

    if len(line.split(" "))<=1:
        print(line)
        print("fail")

