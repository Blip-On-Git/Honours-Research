langs = ["zul","nbl","ssw","xho"]

merged_lex = open(f"lexicon.txt", "w")
merged_nsp = open(f"nonsilence_phones.txt", "w")

merged_nsp.write("nse\n")

single_lang_lexicons = []
single_lang_nsps = []

added_first = False

for lang in langs:

    lexicon = open(f"{lang}_lexicon.txt","r")
    nsp = open(f"{lang}_nonsilence_phones.txt","r")
    
    lexicon_lines = lexicon.readlines()
    nsp_lines = nsp.readlines()

    for  i in range(len(lexicon_lines)):
        if "\n" in lexicon_lines[i]:
            lexicon_lines[i] = lexicon_lines[i].replace("\n","")
        if i!=len(lexicon_lines)-1:
            lexicon_lines[i] = lexicon_lines[i]+"\n"

    for  i in range(len(nsp_lines)):
        if "\n" in nsp_lines[i]:
            nsp_lines[i] = nsp_lines[i].replace("\n","")
        nsp_lines[i] = nsp_lines[i]+"\n"

    # for  i in range(len(lexicon_lines)):
    #     for symbol in ["B", "E", "S", "I"]:
    #         if f"{lang}_{symbol}" in lexicon_lines[i]:
    #             lexicon_lines[i] = lexicon_lines[i].replace(f"{lang}_{symbol}",f"{symbol}_{lang}")

    # for  i in range(len(nsp_lines)):
    #     for symbol in ["B", "E", "S", "I"]:
    #         if f"{lang}_{symbol}" in nsp_lines[i]:
    #             nsp_lines[i] = nsp_lines[i].replace(f"{lang}_{symbol}",f"{symbol}_{lang}")


    if not added_first:
        merged_lex.writelines(lexicon_lines)
        added_first = True
    else:
        merged_lex.writelines(lexicon_lines[3:])

    merged_nsp.writelines(nsp_lines)
    
    
    lexicon.close()
    nsp.close()


merged_lex.close()
merged_nsp.close()        
        




