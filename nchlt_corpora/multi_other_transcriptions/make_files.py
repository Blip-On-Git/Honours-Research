

langs = ["afr","ven","tso"]

filetypes = ["text","wav","utt2spk"]

datasets = ["train","dev","test"]

for filetype in filetypes:
    count = 0
    for dataset in datasets:

        merged_langs = None

        if filetype!="wav":

            merged_langs = open(f"{filetype}_{dataset}", "w")
            single_langs = []

            for lang in langs:

                lang_file = open(f"{lang}_{filetype}_{dataset}","r")
                lines = lang_file.readlines()

                for  i in range(len(lines)):
                    if "\n" in lines[i]:
                        lines[i] = lines[i].replace("\n","")

                single_langs.append(lines)

                lang_file.close()

            max_len = max((len(single_langs[0]), len(single_langs[1]), len(single_langs[2])))

            for i in range(max_len):

                if i<len(single_langs[0]):

                    utt_id_modifer = f"nchlt_other_{count:010d}_"
                    new_line = single_langs[0][i].replace("nchlt_",utt_id_modifer,1)+"\n"
                    line_lang = new_line.split("_")[3]
                    line_spk = new_line.split("_")[4]
                    new_line = new_line.replace(f"_{line_lang}_","_",1)
                    new_line = new_line.replace("nchlt_other_",f"nchlt_other_{line_spk}_",1)
                    new_line = new_line.replace(" ",f"_{line_lang} ",1)

                    merged_langs.write(new_line)
                    count+=1

                if i<len(single_langs[1]):
                    utt_id_modifer = f"nchlt_other_{count:010d}_"
                    new_line = single_langs[1][i].replace("nchlt_",utt_id_modifer,1)+"\n"
                    line_lang = new_line.split("_")[3]
                    line_spk = new_line.split("_")[4]
                    new_line = new_line.replace(f"_{line_lang}_","_",1)
                    new_line = new_line.replace("nchlt_other_",f"nchlt_other_{line_spk}_",1)
                    new_line = new_line.replace(" ",f"_{line_lang} ",1)

                    merged_langs.write(new_line)
                    count+=1

                if i<len(single_langs[2]):
                    utt_id_modifer = f"nchlt_other_{count:010d}_"
                    new_line = single_langs[2][i].replace("nchlt_",utt_id_modifer,1)+"\n"
                    line_lang = new_line.split("_")[3]
                    line_spk = new_line.split("_")[4]
                    new_line = new_line.replace(f"_{line_lang}_","_",1)
                    new_line = new_line.replace("nchlt_other_",f"nchlt_other_{line_spk}_",1)
                    new_line = new_line.replace(" ",f"_{line_lang} ",1)

                    merged_langs.write(new_line)
                    count+=1

        else:
            
            merged_langs = open(f"{filetype}_{dataset}.scp", "w")
            single_langs = []

            for lang in langs:

                lang_file = open(f"{lang}_{filetype}_{dataset}.scp","r")
                lines = lang_file.readlines()

                for  i in range(len(lines)):
                    if "\n" in lines[i]:
                        lines[i] = lines[i].replace("\n","")

                single_langs.append(lines)

                lang_file.close()

            max_len = max((len(single_langs[0]), len(single_langs[1]), len(single_langs[2])))

            for i in range(max_len):
                
                if i<len(single_langs[0]):
                    utt_id_modifer = f"nchlt_other_{count:010d}_"
                    new_line = single_langs[0][i].replace("nchlt_",utt_id_modifer,1)+"\n"
                    line_lang = new_line.split("_")[3]
                    line_spk = new_line.split("_")[4]
                    new_line = new_line.replace(f"_{line_lang}_","_",1)
                    new_line = new_line.replace("nchlt_other_",f"nchlt_other_{line_spk}_",1)
                    new_line = new_line.replace(" ",f"_{line_lang} ",1)

                    merged_langs.write(new_line)
                    count+=1

                if i<len(single_langs[1]):
                    utt_id_modifer = f"nchlt_other_{count:010d}_"
                    utt_id_modifer = f"nchlt_other_{count:010d}_"
                    new_line = single_langs[1][i].replace("nchlt_",utt_id_modifer,1)+"\n"
                    line_lang = new_line.split("_")[3]
                    line_spk = new_line.split("_")[4]
                    new_line = new_line.replace(f"_{line_lang}_","_",1)
                    new_line = new_line.replace("nchlt_other_",f"nchlt_other_{line_spk}_",1)
                    new_line = new_line.replace(" ",f"_{line_lang} ",1)

                    merged_langs.write(new_line)
                    count+=1

                if i<len(single_langs[2]):
                    utt_id_modifer = f"nchlt_other_{count:010d}_"
                    new_line = single_langs[2][i].replace("nchlt_",utt_id_modifer,1)+"\n"
                    line_lang = new_line.split("_")[3]
                    line_spk = new_line.split("_")[4]
                    new_line = new_line.replace(f"_{line_lang}_","_",1)
                    new_line = new_line.replace("nchlt_other_",f"nchlt_other_{line_spk}_",1)
                    new_line = new_line.replace(" ",f"_{line_lang} ",1)

                    merged_langs.write(new_line)
                    count+=1 


        merged_langs.close()

