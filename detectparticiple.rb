@partpenult = "abcdfghjklmnpqrstvwxz"
@unvoiced_partpenult  = "cfhkpqstxz"
@notparticiples = ["ökänd", "mången", "glad", "gedigen", "liten", "hård", "sen", "mycken", "välkommen", "öppen", "ilsken", "egen", "osund", "enskild", "blåögd", "ond", "medveten", "angelägen", "okänd", "kristen", "vuxen", "rädd", "jätte|ond", "jätte|ledsen", "lessen", "sugen", "synd", "ledsen", "mild", "obenägen", "ren", "nämnvärd", "jättesugen", "vaken", "stenhård", "naken", "nyfiken", "högljudd", "galen", "värd", "toppen", "oerhörd", "omedveten", "helhjärtad", "vild", "lyhörd", "avsevärd", "sund", "belägen", "folkvald", "blond", "trogen", "förmögen", "färgglad", "sorgsen", "överlägsen", "outvecklad", "önskvärd", "rund", "belåten", "härsken", "moloken", "grund", "blå|mild", "plikttrogen", "oönskad", "len", "säregen", "mogen", "avlägsen", "älskvärd", "medfaren", "ljummen", "först", "korrekt", "främst", "direkt", "fast", "indirekt", "gôtt", "rätt", "näst", "trist", "exakt", "sist", "glatt", "övertrött", "perfekt", "tyst", "flott", "förtjust", "platt", "nätt", "sankt", "terrest", "ogift", "rödlätt", "storväxt", "kroknäst", "kompakt", "knäppt", "smått"]


def detectparticiple(pos,upos,lemma,head,deprel,sentence,sent_id)
    feats = []
    if pos == "AJ" 
        if ((lemma[-1] == "d" and @partpenult.include?(lemma[-2])) or (lemma[-2..-1] == "en") or (lemma[-1] == "t" and @unvoiced_partpenult.include?(lemma[-2]))) and !@notparticiples.include?(lemma)
            if !sentence[head].nil?
                if sentence[head]["lemma"] == "bli" and deprel == "SP"
                    upos = "VB"
                    feats << "Voice=Pass"
                elsif deprel == "KL"
                    headhead = sentence[head]["head"]
                    headdeprel = sentence[head]["deprel"]
                    #STDERR.puts "checking the headhead of a potential bli-passive #{sent_id}"
                    if !sentence[headhead].nil?
                        if sentence[headhead]["lemma"] == "bli" and headdeprel == "SP"
                            #STDERR.puts "Found the headhead! #{sent_id}"
                            upos = "VB"
                            feats << "Voice=Pass"
                        end
                    end

                    #TODO3: change the structure, add aux:pass deprel, change POS of bli to "aux"
                end
            end
            feats << "Tense=Past"
            feats << "VerbForm=Part"
        elsif lemma[-4..-1] == "ande" or lemma[-4..-1] == "ende" 
            feats << "Tense=Pres"
            feats << "VerbForm=Part"
        end
    end
    return upos,feats
end
