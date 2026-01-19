require_relative 'detectparticiple.rb'
mode = "convert"
list_out_pos = false
lemma_per_pos2 = Hash.new{|hash, key| hash[key] = Array.new}

filename = ARGV[0]
inputfile = File.open("#{filename}.conllu","r:utf-8")
@verbose = false
#@jfuposs = []
@clauses1 = Hash.new{|hash, key| hash[key] = Array.new}

if mode == "convert"
    
    outputfile_pos = File.open("#{filename}_ud_pos.conllu","w:utf-8")
    outputfile_syntax = File.open("#{filename}_ud.conllu","w:utf-8")
elsif mode == "list_pos"
    ref_pos = ARGV[1]
    if ref_pos == "??"
        ref_pos2 = "QQ"
    else
        ref_pos2 = ref_pos
    end
    pos_outputfile = File.open("#{ref_pos2}_#{filename}.txt","w:utf-8")
    #lemmas_per_pos = Hash.new{|hash, key| hash[key] = Hash.new(true)}
    lemmas_per_pos = Hash.new(true)
end

@matchingu = {"PE" => "ADP","AJ" => "ADJ","NN"=>"NOUN","EN"=>"PROPN", "SY"=>"PUNCT", "IJ"=>"INTJ", "KO" => "CCONJ", "AB" => "ADV", "NU" => "NUM", "PO" => "PRON", "SU" => "SCONJ", "UO" => "X", "VB" => "VERB"}

@all_upos = ["ADJ", "ADP", "ADV", "AUX", "CCONJ", "DET", "INTJ", "NOUN", "NUM", "PART", "PRON", "PROPN", "PUNCT", "SCONJ", "SYM", "VERB", "X"]

@mycketlemmas = {"mycken" => "mycket", "litet" => "lite", "mången" => "många", "flera" => "många"}
#handling elsewhere: KL, HD, DF, DT, MD

@matchdeprels = {"ME"=>"fixed", "PL"=>"compound:prt","IV"=>"xcomp","--"=>"discourse","OP"=>"xcomp","SP"=>"xcomp"} #"HD"=>"dep",


@matchdeprels_old = {"SB"=>"nsubj", "OO" => "obj", "AG"=>"obl:agent","AN"=>"appos", "EF"=>"acl:cleft", "EO" => "obj", "ES" => "nsubj","IO"=>"iobj","ME"=>"fixed","OA"=>"advcl","OP"=>"xcomp","PL"=>"compound:prt","RA"=>"advmod","SP"=>"xcomp","IV"=>"xcomp","--"=>"discourse"} #"HD"=>"dep",

@functionwords = ["ADP","SCONJ","PART","DET","AUX","CCONJ","SYM","PUNCT"] #NO: ,NUM,PRON,X,INTJ.

#TODO: DF -- better distinction between parataxis and discourse
#TODO: rehang comparison in periphrastic constructions ("När det finns perifrastisk komparation hängs det på huvudordet i kvaliteten och inte på modifieraren: mera kompetent än X borde har än X som dependent till kompetent. I Eukalyptus hängs det nog på mera, så det får man rätta till i konverteringen. (Samma gäller lika bra som X etc.)")

=begin
#TODONOW: Gerlof, clausal relationships (OO etc.), SCONJ, PH (deal with som first), OA, RA (parent and child), check all E*, udeprel validation, from UD side, go through existing issues, go through TODOs, metadata, evaluation... Split, validation, documentation

Lista 0: clause or not 
TODO: "SB"=>"nsubj/csubj", "OO" => "obj/ccomp", "AG"=>"obl:agent/advcl, if any?", "IO"=>"iobj/advcl, if any?", AN (appos/??), OA (+adverbial or not?), 


Lista 1: one-to-one mappings list
DONE: PL, ME, OP, SP

Lista 2: special functions
DONE:  JF, MD, DF, DT
TODO: RA (check for clauses?)

Lista 3: covered by other rules
DONE: KL, 
DONE+1: --, IV
TODO: PH,

TOSORT: 
EF (typ acl:cleft?), EO (asked), ES (nsubj,csubj? expl for det)

From UD:
https://universaldependencies.org/sv/dep/index.html
acl
:relcl
:outer
:pass
:cleft
flat, flat:name

list, dislocated, orphan

=end


#TODO technical: uniform methods for swapping heads and reassigning PhraseCat
#TODO at evaluation: clausal vs non-clausal? Should PhraseCat in eukxml be assigned from Top, as it is now? Will eventually become TODO-DIM
#TODO: deal with fake-coords manually

#Major: Heads and dependents, clauses vs non-clauses, previous conversion (MWE), coordination. Go from UD relations
#Do a split?
# Fix ill-formed trees 1) check Gerlof; 2) disconnected+MWE 3) rest 4) KoP and head assignment? 5)double-check that old ones got fixed correcty
#Look into: AN, EF, EO, ES, KL, ME, OA, PH, RA:advcl?, OP+SP. 
# Not listed: "DF"=>"discourse" (parataxis?), IV: always aux?, "JF", MD, --: root, punct, not inherited
## punctuation assignment


@ordnums = ["första", "fjortonde", "andra", "25:e", "tredje", "fjärde", "femte", "sjätte", "sjunde", "nionde", "elfte", "tolfte", "trettonde", "femtonde", "sextonde", "sjuttonde", "artonde", "nittonde", "700:e", "tionde", "åttonde", "III"] #"annan"

#TODO0: All fixed expressions must have the first word as root.
#TODO-DIM:  But then, we'd have to deal with many fixed expressions manually in any case, since they are not actually fixed in UD...
#TODO1: more ordnum lemmas (generate? or split and analyze?)
#TODO2: WAITING determiners
#TODO2: WAITING Add verbal features for participles? Or exclude them from the participle function?


@matchingp = {"PE" => "PP"}
@matchfeats = {"-.-.-" => "_", "IND" => "Definite=Ind", "DEF" => "Definite=Def", "POS" => "Degree=Pos", "KOM" => "Degree=Cmp", "SUV"=> "Degree=Sup", "UTR" => "Gender=Com", "NEU" => "Gender=Neut", "MAS" => "Gender=Masc", "SIN" => "Number=Sing", "PLU" => "Number=Plur", "SUB" => "Case=Nom", "OBJ" => "Case=Acc", "PSS"=>"Poss=Yes"}
#"UTR/NEU" => "Gender=Com,Neut", "IND/DEF" => "Definite=Ind,Def", "SIN/PLU" => "Number=Sing,Plur", "SUB/OBJ" => "Case=Acc,Nom" Decided not to add. Usually covers the full range of possible values (and thus not recommended). Exception: Gender (Masc), but it's marginal. Syncretic case in EUK applies (mostly?) to determiners, so not relevant either.

@matchvbfeats = {"IND" => "Mood=Ind", "AKT" => "Voice=Act", "PRS" => "Tense=Pres", "PRT" => "Tense=Past", "SFO" =>"Voice=Pass", "KON" => "Mood=Sub", "IMP" => "Mood=Imp", "INF" => "VerbForm=Inf", "SPM" => "VerbForm=Sup", "SIN" => "Number=Sing", "PLU" => "Number=Plur", "SUB" => "Case=Nom", "OBJ" => "Case=Acc", "UTR" => "Gender=Com", "NEU" => "Gender=Neut", "MAS" => "Gender=Masc"}

#TODO0: shared dependents, e.g. Regr_255284.11
#TODO0: stranded prepositions: use secedges to reassign correctly

#TODO3: Blog_265827-14454566.3: har suttit och pluggat is not really perfect. Possible to do better?
#TODO3: Blog_265827-14989915.2 wrong
#TODO3: Asyndetic coordination: KL hangs on nothing. Check cases like Romn_Lundqvist-Ingentobak.70, remove KL from ROOT
#TODO3: Deal with ESM in msd2
#TODO3: Misc for MWEs?
#TODO3: PL => compound:prt. Current UD inconsistent
#TODO3: DO when syntax. SCONJ vs PRON vs ADV (som). Identify Advcl (esp. när, då, där). Deal with än and som Come back to https://github.com/UniversalDependencies/docs/issues/1092
#TODO3: vilket fall som helst: CCONJ. Så: many cases of ADV should be CCONJ?
#TODO3: ASK: advcl (sv-ud-train-3749, sv-ud-train-166) -- should be SCONJ. 
#TODO3: Arbt_Fackfientlig.7 -- ask Gerlof
#TODO3: Arbt_Fackfientlig.2, 1003: 1008:
#TODO3: den här (also change POS annotation for den)

#DIM (DOC, IGNORE, MANUALLY, LATER)
# MANUALLY: Blog_54523-8202951.11 visst to ADV
# allting annat
# EN: numeral
# Typo should be style, too
# AUX-VERB
# FRL -- use to find SUBORDINATORS?
# Underproduction of PROPN (turn back on the capitalization-based method?)
# annat fint
# lemmatization of "andra" 
# NumType
# ASK: verbal particles: when ADV, when ADP? Also in texts, but there the rule is clearer
# vad, vilken (+vem? det?) and other ambiguous
# ASK: särskilt
# Int,Rel
# ranges (1986-87, 2000-2006, 08.15-09.30) seem to be inconsinsently tokenized. UD policy unknown to me.
# Eupa_00-01-17.301, 44: särskilt should be ADV
# UO->X: manually make them analyzable
# Fixed expressions: make them analyzable

@auxlist = ["böra", "få", "komma", "kunna", "lär", "må", "måste", "skola", "torde",  "vilja", "bli", "ha", "vara"]   #from https://quest.ms.mff.cuni.cz/udvalidator/cgi-bin/unidep/langspec/specify_auxiliary.pl?lcode=sv with changes discussed in https://github.com/UniversalDependencies/docs/issues/1082
@adverbial_heads = ["AJ","VB"] 
@determiners = ["den", "en", "all", "någon", "denna", "vilken", "ingen", "varannan", "varenda","de","varje","båda","bägge","var","varannan","varenda","ena","allting"]
@posslemmas = {"min" => "jag", "din" => "du", "vår" => "vi", "er" => "ni", "sin" => "sig"}
@lemmacorrections = {"en viss" => "viss"}
@uposcorrections = {"viss" => "ADJ"}
@adpnotadv = ["från", "av", "i", "mot", "på", "mellan", "å", "hos", "bland", "inom", "utom", "per", "trots", "förutom","utöver"]

@prontypes = {"all" => "Tot", "annan" => "Ind", "denna" => "Dem", "densamma" => "Dem", "en" => "Art", "hon" => "Prs", "ingen" => "Neg", "ingenting" => "Neg", "man" => "Ind", "någon" => "Ind", "sig" => "Prs", "som" => "Rel", "var" => "Tot", "varandra" => "Rcp", "vardera" => "Tot", "varje" => "Tot", "vem" => "Int", "the" => "Art", "vars" => "Rel", "vilka" => "Rel", "du" => "Prs", "vi" => "Prs", "han" => "Prs", "jag" => "Prs", "ni" => "Prs", "vår" => "Prs", "mitt" => "Prs", "mycken" => "Ind", "någonting" => "Ind", "mången" => "Ind", "mycket" => "Ind", "sån" => "Ind", "somlig" => "Ind", "lite" => "Ind", "många" => "Ind", "varannan" => "Ind", "nånting" => "Ind", "flera" => "Ind", "fler" => "Ind", "få" => "Ind", "två" => "Ind", "vissa" => "Ind", "båda" => "Tot", "vilket" => "Tot", "bådadera" => "Tot", "allting" => "Tot", "envar" => "Tot", "bägge" => "Tot", "samtlig" => "Tot", "alltihop" => "Tot", "ingendera" => "Neg", "varann" => "Rcp", "vad" => "Int,Rel", "vilken" => "Int,Rel", "litet" => "Ind", "allihopa" => "Tot", "alltihopa" => "Tot", "varsin" => "Tot", "varenda" => "Tot", "allesammans" => "Tot", "ena"=>"Tot"} #Based on Talbanken + corrections from https://github.com/UniversalDependencies/docs/issues/1083#issuecomment-2677651632


@nonsfolemmas = ["tycka", "möta", "fordra", "känna", "tränga"] #both from Talbanken and LinES with manual filtering

def verbal_or_not(sentence,id,verbalcats)
    verbal = false
    @copula = false
    upos = sentence[id]["upos"]
    if verbalcats.include?(upos)
        verbal = true
    else
        daughters = finddaughters(sentence,id)
        daughters.each do |daughter|
            if sentence[daughter]["deprel"] == "cop" #and sentence[daughter]["upos"] == "AUX"
                verbal = true
                @copula = true
                break
            end
        end
    end
    return verbal
end

def finddaughters(sentence,nodeofinterest)
    daughters = []
    sentence.each_pair do |id, infohash|
        if infohash["head"] == nodeofinterest
            daughters << id
        end
    end
    return daughters

end

def adverbials(id, sentence, sent_id)
    form,lemma,pos,msd,msd2,head,deprel,enhdep,misc = getinfofromsentence(sentence,id)
    if ((pos == "AJ" and msd.include?("SIN") and msd.include?("IND") and msd.include?("NEU")) and check_adverbial_head(id, sentence, sent_id)) or (pos == "AJ" and lemma == "först")
        upos = "ADV"
        lemma = form.clone 
    end 
    return upos,lemma
end

def check_adverbial_head(id, sentence, sent_id)
    form,lemma,pos,msd,msd2,head,deprel,enhdep,misc = getinfofromsentence(sentence,id)
    flag = false
    if ((sentence[head].nil? or (@adverbial_heads.include?(sentence[head]["pos"]) and sentence[head]["lemma"] != "vara") and deprel == "MD"))
        flag = true
    elsif go_up(id,sentence,sent_id,"check_adverbial_head")
        flag = true
        #STDERR.puts "#{sent_id}, #{id}"
    end
    return flag
end

def go_up(id,sentence,sent_id,method)
    #STDERR.puts "#{sent_id}, #{id}, #{sentence[id]["form"]}"
    flag = false
    deprel = sentence[id]["deprel"]
    if deprel == "KL"
        head = sentence[id]["head"]
        #headhead = sentence[head]["head"]
        headdeprel = sentence[head]["deprel"]
        if headdeprel == "KL" #sentence[headhead]["pos"] == "KO" or sentence[head]["pos"] == "SY"
            #head = sentence[head]["head"]
            #STDERR.puts "Recursion! #{sent_id}, #{id}"
            go_up(head,sentence,sent_id,method)
        else
            flag = send(method, head,sentence,sent_id)
        end
    end
    return flag
end

def buildtopdowntree(sentence)
    topdown = Hash.new{|hash, key| hash[key] = Array.new}
    sentence.each_pair do |id,senthash|
        head = senthash["head"]
        topdown[head] << id
    end    
    topdown
end

def getinfofromsentence(sentence,id)
    form = sentence[id]["form"]
    lemma = sentence[id]["lemma"]
    pos = sentence[id]["pos"]
    msd = sentence[id]["msd"]
    msd2 = sentence[id]["msd2"]
    head = sentence[id]["head"]
    deprel = sentence[id]["deprel"]
    enhdep = sentence[id]["enhdep"]
    misc = sentence[id]["misc"]
    return form,lemma,pos,msd,msd2,head,deprel,enhdep,misc
end

def find_next_conjunct(target,conjuncts)
    answer = nil
    #STDERR.puts target
    #STDERR.puts conjuncts.join(" ")
    #STDERR.puts conjuncts.sort.join(" ")


    conjuncts.sort.each do |conjunct|
        #STDERR.puts conjunct
        if conjunct > target             
            answer = conjunct.clone
            break
        end
        
    end
    #STDERR.puts answer
    return answer
end

@chain_array = []

def clause_or_not(phrasecat,upos,sent_id,id,wherefrom)
    if @markcats.include?(phrasecat) and ["VERB","AUX"].include?(upos)
        #@clauses1[wherefrom] << "SM\t#{sent_id}\t#{id}\t#{wherefrom}"
    elsif  @markcats.include?(phrasecat) and !["VERB","AUX"].include?(upos)    
        @clauses1[wherefrom] << "S\t#{sent_id}\t#{id}\t#{wherefrom}"
    elsif !@markcats.include?(phrasecat) and ["VERB","AUX"].include?(upos)    
        @clauses1[wherefrom] << "M\t#{sent_id}\t#{id}\t#{wherefrom}"
    end
end

def findfunchead_topdown(sent_id,topdown,sentence,id,firsthead,chain)
    
    if !topdown[id].empty? 
        if id != 0 and @functionwords.include?(sentence[id]["upos"])
            topdown2 = []
            topdown[id].each do |daughter|
                if sentence[daughter]["deprel"] != "conj" and sentence[daughter]["deprel"] != "parataxis"
                    topdown2 << daughter
                end
            end
            if !topdown2.empty?
                #STDERR.puts id
                if firsthead
                    #@functional_head = id.clone
                end
                #@daughters_of_functional_head[id] = topdown[id]
                chain << "#{id}-#{sentence[id]["upos"]}|#{sentence[id]["form"]}|#{sentence[id]["head"]}|#{sentence[id]["deprel"]}"
                topdown2.each do |daughter|
                    findfunchead_topdown(sent_id,topdown,sentence,daughter,false,chain)
                end
                @chain_array << "#{sent_id}\t#{chain.join(" ")}\t#{chain.length}"
            end
        else
            topdown[id].each do |daughter|
               findfunchead_topdown(sent_id,topdown,sentence,daughter,true,[])
            end
        end
    end
end

@markcats = ["S","SuP","VP","VBM"]


def convert_coordination(sentence2, sent_id)
    sentence = sentence2.clone
    root = nil
        
    sentence.each_pair do |id,senthash|
        if senthash["head"] == 0
            root = id.clone            
        end
    end
    
    loop do #coordination
        nokl = true
        chain_conjuncts = Hash.new{|hash, key| hash[key] = Array.new} #{"head"=>nil, "dependents"=>[]}
        chain_other_conjunctions = Hash.new{|hash, key| hash[key] = Array.new}
        chain_other_daughters = Hash.new{|hash, key| hash[key] = Array.new}

        sentence.each_pair do |id,senthash|
            deprel = senthash["deprel"]
            head = senthash["head"]
            pos = senthash["pos"]
        
            if (deprel == "KL") #and !processed_conjuncts.include?(id) #pre-converted parataxis not included, since it's already in the UD format
                nokl = false
                #STDERR.puts head
                conjunction_daughters = finddaughters(sentence,head)
            
                conjunction_daughters.each do |daughter|
                    if sentence[daughter]["deprel"] == "KL" 
                        chain_conjuncts[head] << daughter
                    elsif sentence[daughter]["pos"] == "KO"
                        if sentence[daughter]["deprel"] == "PH"
                            chain_other_conjunctions[head] << daughter
                        else
                            chain_other_daughters[head] << daughter
                            #STDOUT.puts "KO_not_under_PH\t#{sent_id}\t#{head}\t#{daughter}"
                        end
                    else
                        chain_other_daughters[head] << daughter
                    end
                end
                break
            end
        end
        #STDERR.puts 
        #STDERR.puts "conjuncts: #{chain_conjuncts}"
        #STDERR.puts "other conjunctions: #{chain_other_conjunctions}"
        #STDERR.puts "other daughters: #{chain_other_daughters}"
        #STDERR.puts 
        
        if nokl
            break
        else
            coordination_heads = chain_conjuncts.keys
            headstatus = ""
            coordination_heads.each do |coordination_head|
                #STDERR.puts coordination_head
                if coordination_head == 0
                    status = "root"
                elsif sentence[coordination_head]["pos"] == "SY"
                    status = "punctuation"
                elsif sentence[coordination_head]["pos"] == "KO"
                    status = "conjunction"
                else
                    status = "other"
                end
                #STDERR.puts status
            
                chain_conjuncts[coordination_head].sort!
                if status == "conjunction" or status == "punctuation" or status == "other"
                    new_coordination_head = nil
                    chain_conjuncts[coordination_head].each.with_index do |conjunct,index|
                        if index == 0
                            new_coordination_head = conjunct.clone
                 #           STDERR.puts new_coordination_head
                            #STDOUT.puts "#{sent_id}\t#{coordination_head}\t#{new_coordination_head}"
                            sentence[new_coordination_head]["deprel"] = sentence[coordination_head]["deprel"].clone
                            sentence[new_coordination_head]["head"] = sentence[coordination_head]["head"].clone
                            if status == "punctuation"
                                sentence[coordination_head]["head"] = root.clone #TODO: on nearest conjunct?
                                sentence[coordination_head]["deprel"] = "punct"
                            elsif status == "conjunction"
                                sentence[coordination_head]["deprel"] = "cc"
                                sentence[coordination_head]["head"] = find_next_conjunct(coordination_head,chain_conjuncts[coordination_head])
                            elsif status == "other"
                                
                                #as EUK-coordination if till, mot etc?
                                new_coordination_head = coordination_head.clone
                                sentence[conjunct]["head"] = new_coordination_head.clone
                                sentence[conjunct]["deprel"] = "conj" 
                                
                                conjuncts_pos = []
                                [coordination_head, chain_conjuncts[coordination_head]].flatten.each do |conjunct2|
                                    conjuncts_pos << sentence[conjunct2]["pos"]
                                end
                                #TODO?
                                if conjuncts_pos.uniq.length > 1
                                    #STDOUT.puts "#{sent_id}\t#{new_coordination_head}\t#{conjuncts_pos.uniq.join(" ")}"
                                end

                                #sentence[coordination_head]["deprel"] = "dep"
                                #sentence[coordination_head]["head"] = new_coordination_head.clone

                            end
                        else
                            sentence[conjunct]["head"] = new_coordination_head.clone
                            sentence[conjunct]["deprel"] = "conj" #TODO: parataxis for clauses?
                        end
                    end
                    chain_other_daughters[coordination_head].each do |other_daughter|
                        sentence[other_daughter]["head"] = new_coordination_head.clone
                    end
                    chain_other_conjunctions[coordination_head].each do |other_conjunction|
                        sentence[other_conjunction]["deprel"] = "cc"
                        sentence[other_conjunction]["head"] = find_next_conjunct(other_conjunction,chain_conjuncts[coordination_head])
                    end
                elsif status == "root"
                    sentence[chain_conjuncts[coordination_head].min]["deprel"] = "root"
                    chain_conjuncts[coordination_head].each.with_index do |conjunct,index|
                        if index > 1
                            sentence[conjunct]["deprel"] = "conj"
                        end
                    end
                end
                
            end
        end
        sentence.each_pair do |id,senthash|
            if senthash["head"] == 0
                root = id.clone            
            end
        end 
    end
    return sentence

end

def convert_syntax(sentence2, sent_id)
    sentence = sentence2.clone
    root = nil
    
    uheads = {}
    udeprels = {}
    umisc = Hash.new{|hash, key| hash[key] = Array.new}

    sentence.each_pair do |id,senthash|
        if senthash["head"] == 0
            root = id.clone            
        end
    end
    
#swapping function-content
    heads_to_ignore = []
    daughters_to_ignore = []
#=begin		
    #sentence.each_pair do |id,senthash|
    #    STDERR.puts "#{id}\t#{senthash}"
    #end
    #STDERR.puts ""
        

    loop do 
        no_functional_heads = true
        functional_head = nil
        sentence.each_pair do |id,senthash|
            #@daughters_of_functional_head = []
            head = sentence[id]["head"]
            
            if head != 0 and sentence[id]["deprel"] != "conj" and sentence[id]["deprel"] != "parataxis" and sentence[id]["deprel"] != "cc" and sentence[id]["deprel"] != "ME" and @functionwords.include?(sentence[head]["upos"]) and !heads_to_ignore.include?(head)
                functional_head = sentence[id]["head"].clone
                no_functional_heads = false
                break
            end
            #if !@functional_head.nil?
                
            #end
            
        end
        
        if !functional_head.nil?
            headupos = sentence[functional_head]["upos"]
            daughters = finddaughters(sentence,functional_head)
            
            if @verbose
                #STDOUT cases when a functional head has a dependent negation word
                negationwords = ["inte","icke","ej","inget","varken","aldrig"]
                daughters.each do |daughter|
                    if negationwords.include?(sentence[daughter]["form"])
                        STDOUT.puts "Negation daughter on a functional word\t#{sent_id}\t#{functional_head}\t#{sentence[functional_head]["form"]}\t#{daughter}\t#{sentence[daughter]["form"]}"
                    end
                    
                end
            end
            
            functionalheads_head = sentence[functional_head]["head"]
            contenthead = nil
            if headupos == "SCONJ" or headupos == "ADP" or (headupos == "PART" and sentence[functional_head]["lemma"] == "att")
                funcheadtype = "adp"
            elsif (headupos == "PART" and sentence[functional_head]["lemma"] != "att")
                funcheadtype = "inte"
            elsif headupos == "AUX"
                funcheadtype = "aux"
            elsif headupos == "DET"
                funcheadtype = "det"
            elsif headupos == "PUNCT"
                funcheadtype = "punct"
            elsif headupos == "SYM"
                funcheadtype = "sym"
            end
            #STDERR.puts functional_head
            #STDERR.puts funcheadtype
            #STDERR.puts "daughters: #{daughters.join(" ")}"
            
            if funcheadtype == "adp"
                daughters.each do |daughter|
                    if sentence[daughter]["deprel"] == "OO"
                        contenthead = daughter.clone
                        break
                    end
                end
                if contenthead.nil? 
                    daughters.each do |daughter|
                        if sentence[daughter]["deprel"] == "MD"
                            if !(sent_id == "Wiki_Sverigesriksdag.73" and daughter == 18)
                                contenthead = daughter.clone                             
                                break
                            end
                        end
                    end
                end
            elsif funcheadtype == "inte"
                reassigned_without_fullswap = true
                if functionalheads_head != 0
                    daughters.each do |daughter|
                        sentence[daughter]["head"] = functionalheads_head
                    end
                end
            elsif funcheadtype == "det"
                reassigned_without_fullswap = true
                if daughters.length == 1 
                    if (sentence[daughters[0]]["lemma"] == "här" or sentence[daughters[0]]["lemma"] == "där")
                        sentence[daughters[0]]["head"] = functionalheads_head
                        sentence[daughters[0]]["deprel"] = "advmod"
                    elsif sentence[daughters[0]]["lemma"] == "viss"
                        sentence[daughters[0]]["head"] = functionalheads_head
                        sentence[daughters[0]]["deprel"] = "amod"
                    end
                end
            elsif funcheadtype == "aux"
                daughters.each do |daughter|
                    if sentence[daughter]["deprel"] == "IV" and !daughters_to_ignore.include?(daughter)
                        contenthead = daughter.clone
                        #heads_to_ignore << functional_head
                        daughters_to_ignore << functional_head
                        break
                    end
                end
                if contenthead.nil?
                    daughters.each do |daughter|
                        if sentence[daughter]["deprel"] == "SP"
                            contenthead = daughter.clone
                            break
                        end
                    end
                end
            elsif funcheadtype == "punct"
                reassigned_without_fullswap = true
                sentence[daughters[0]]["head"] = functionalheads_head.clone
                sentence[functional_head]["head"] = daughters[0].clone
                sentence[functional_head]["upos"] = "SYM"
                #if sent_id == "Blog_12325-2172538.4"
                #    sentence[daughters[0]]["deprel"] = "nummod"			
                #    sentence[functional_head]["deprel"] = "case"
                #else			    
                sentence[daughters[0]]["deprel"] = "nmod"			
                sentence[functional_head]["deprel"] = "case"
                #end
                #STDERR.puts "contenthead=#{contenthead}"
            elsif funcheadtype == "sym"
                reassigned_without_fullswap = true
                symlemma = {"%" => "procent", "º" => "grader", "#" => "nummer", "µm" => "mikrometer", "°C" => "grader"}			
                sympos = {"%" => "NOUN", "º" => "NOUN", "#" => "NOUN", "µm" => "NOUN", "°C" => "NOUN"}
                sentence[functional_head]["upos"] = sympos[sentence[functional_head]["form"]]
                sentence[functional_head]["lemma"] = symlemma[sentence[functional_head]["form"]]				
            end
            
            if contenthead.nil? 
                #STDERR.puts "No content head!"
                if @verbose 
                    #STDOUT cases when a lexical head cannot be found
                    if reassigned_without_fullswap != true
                        if funcheadtype == "det" or (findinset(sent_id,"PromotedHead", sentence[functional_head]["misc"],sentence,functional_head) != "Yes" and !findinset(sent_id,"ExtXpos",sentence[functional_head]["misc"],sentence,functional_head).to_s.match?(/[A-Z][A-Z]M/))
                            
                            if functionalheads_head == 0
                                headheadform = "root"
                            else
                                headheadform = sentence[functionalheads_head]["form"]
                            end
                            
                            if headheadform != "root"
                                STDOUT.puts "No lexical head found!\t#{sent_id}\t#{functional_head}\t#{headupos}\t#{sentence[functional_head]["form"]}\t#{daughters.length}\t#{sentence[daughters[0]]["form"]}\t#{headheadform}\t#{sentence[daughters[0]]["deprel"]}"  
                            end
                        
                        end
                    end
                end
                heads_to_ignore << functional_head
                #TODO: part of ME
                #misannotations
            else
                #STDERR.puts "Contenthead #{contenthead}"
                #STDERR.puts sentence[functional_head]["form"]
                #STDERR.puts sentence[functional_head]["deprel"]
                #STDERR.puts sentence[functional_head]["head"]
                
                #STDERR.puts headupos
                if sentence[functional_head]["deprel"] == "conj" or sentence[functional_head]["deprel"] == "ME"
                    #STDERR.puts sentence[sentence[functional_head]["head"]]["upos"]    
                    headheadupos = sentence[sentence[functional_head]["head"]]["upos"]
                    #STDOUT.puts "#{sent_id}\t#{headupos}\t#{headheadupos}\t#{sentence[functional_head]["deprel"]}"
                    if headheadupos == headupos or ["ADV","SCONJ"] == [headheadupos,headupos].sort or ["ADV","ADP"] == [headheadupos,headupos].sort
                        functional_head = sentence[functional_head]["head"].clone 
                        daughters = finddaughters(sentence,functional_head)
                        #STDERR.puts "Functional head changed!"
                    end
                end
                
                
                sentence[contenthead]["head"] = sentence[functional_head]["head"].clone
                func_phrasecat = findinset(sent_id,"PhraseCat",	sentence[functional_head]["misc"],sentence,functional_head)
                cont_phrasecat = findinset(sent_id,"PhraseCat",	sentence[contenthead]["misc"],sentence,contenthead)
                if cont_phrasecat.to_s == ""
                    umisc[contenthead].reject!{|s| s.include?("PhraseCat")}
                    umisc[contenthead] << "PhraseCat=#{func_phrasecat}"
                    #STDERR.puts "CHS\t#{contenthead}\t#{umisc[contenthead].join(" ")}"
                end
                
                
                if !(funcheadtype == "aux" and sentence[functional_head]["deprel"]=="IV")
                    sentence[contenthead]["deprel"] = sentence[functional_head]["deprel"].clone
                end
                sentence[functional_head]["head"] = contenthead.clone
                #if sentence[functional_head]["misc"]==""
                    umisc[functional_head] << "NewHead=#{contenthead}"
                #else
                #    umisc[functional_head] << "#{sentence[functional_head]["misc"]}|NewHead=#{contenthead}"
                #end
                
                if funcheadtype == "adp"
                    #TODO: look at rels or PhraseCat instead?
                    phrasecat = findinset(sent_id,"PhraseCat",	sentence[functional_head]["misc"],sentence, functional_head)
                    
                    
                    if phrasecat == "PP"
                        #STDOUT.puts "Phrasecat=PP\tSWAP:ADP\t#{sent_id}\t#{functional_head}"
                        phrasecat = findinset(sent_id,"PhraseCat",	sentence[sentence[functional_head]["head"]]["misc"],sentence,sentence[functional_head]["head"])
                    end
                    
                    
                    if @markcats.include?(phrasecat) #will be corrected later by verbal_or_not
                        sentence[functional_head]["deprel"] = "mark"
                        #STDOUT.puts "mark\tSWAP:ADP\t#{sent_id}\t#{functional_head}"
                    else #In many cases PhraseCat will be empty, e.g. in a usual NP. These cases will correctly get "case"
                        sentence[functional_head]["deprel"] = "case"
                        #STDOUT.puts "case\tSWAP:ADP\t#{sent_id}\t#{functional_head}"
                    end
                    #if phrasecat.to_s == ""
                    #    STDOUT.puts "No PhraseCat\tSWAP:ADP\t#{sent_id}\t#{functional_head}"
                    #end
                elsif funcheadtype == "aux"
                    if sentence[functional_head]["lemma"] == "vara"
                        sentence[functional_head]["deprel"] = "cop"
                    else
                        sentence[functional_head]["deprel"] = "aux"
                    end
                    
                end
                
                daughters.each do |daughter|
                   
                    if daughter != contenthead 
                        if !(sent_id == "Wiki_Sverigesriksdag.73" and daughter == 18)
                            #STDERR.puts "reassigning #{daughter} to #{contenthead}"
                            sentence[daughter]["head"] = contenthead.clone
                        end
                    end
                    
                end
                #STDERR.puts sentence	
            end
        end
        #STDERR.puts "inte daughter of #{sentence[sentence[18]["head"]]["form"]}"
        
        if no_functional_heads
            break
        end
    end
#=end


#swapping head-dependent for adverbs that govern smth (mostly verbs) via OO.
    sentence.each_pair do |id,senthash|
        daughters = finddaughters(sentence, id)
        if senthash["upos"] == "ADV"
            #swapflag = false
            daughters.each do |daughter|
                if sentence[daughter]["deprel"] == "OO"
                    #STDOUT.puts "ADV governs OO\t#{sent_id}\t#{senthash["form"]}\t#{senthash["deprel"]}\t#{sentence[daughter]["upos"]}"
                    advhead = id.clone
                    newhead = daughter.clone
                    adv_phrasecat = findinset(sent_id,"PhraseCat",	sentence[advhead]["misc"], sentence, advhead)
                    new_phrasecat = findinset(sent_id,"PhraseCat",	sentence[newhead]["misc"], sentence, newhead)
                    if new_phrasecat.to_s == ""
                        umisc[newhead].reject!{|s| s.include?("PhraseCat")}
                        umisc[newhead] << "PhraseCat=#{adv_phrasecat}"
                        #STDOUT.puts "ADVPCSWAP:#{sent_id}\t#{newhead}"
                    end
                
                    
                    
                    sentence[newhead]["head"] = sentence[advhead]["head"].clone
                    sentence[newhead]["deprel"] = sentence[advhead]["deprel"].clone
                    sentence[advhead]["head"] = newhead.clone
                    sentence[advhead]["deprel"] = "advmod"
                    daughters.each do |daughter1|                
                        if daughter1 != newhead
                            sentence[daughter1]["head"] = newhead.clone                           
                        end
                    end
                end            
            end
        end
    end
    

#som helst
    sentence.each_pair do |id,senthash|
        lemma = senthash["lemma"]
        deprel = senthash["deprel"]
        head = senthash["head"]
        
        if lemma == "som" and sentence[id+1]["lemma"] == "gärna" 
            if ((sentence[id+1]["head"] == id) or (sentence[id+1]["head"] == head)) #or (head == id+1)
                sentence[id]["deprel"] = "advmod"
                sentence[id+1]["deprel"] = "fixed"
                sentence[id+1]["head"] = id.clone
            elsif head = id+1
                sentence[id]["deprel"] = "advmod"
                sentence[id+1]["deprel"] = "fixed"
                sentence[id]["head"] = sentence[id+1]["head"].clone
                sentence[id+1]["head"] = id.clone
            end
        end
    end

#själv
#see https://github.com/UniversalDependencies/docs/issues/1126
    sentence.each_pair do |id,senthash|
        lemma = senthash["lemma"]
        
           
        if lemma == "själv" 
            head = senthash["head"]
            
            if head == 0
                STDOUT.puts "SJÄLV is root! #{sent_id}"
            else
                headupos = sentence[head]["upos"]			
               
                if headupos == "VERB" or headupos == "INTJ"
                    sentence[id]["deprel"] = "advcl"
                elsif headupos == "NOUN" or headupos == "PROPN"
                        if id < head and senthash["feats"].include?("Definite=Def")
                            sentence[id]["deprel"] = "amod"
                        else
                            sentence[id]["deprel"] = "acl"
                        end
                elsif headupos == "PRON"
                    sentence[id]["deprel"] = "acl"
                else
                    STDOUT.puts "Lost SJÄLV! #{sent_id} #{headupos}"
                end
            end
                    
        
        end
    end

#remaining cases. No tree-structure changes should occur in the loop below, and the idea is that conversion rules are independent of one another
    
    sentence.each_pair do |id,senthash|
        #STDERR.puts "#{id} #{senthash}"
        deprel = senthash["deprel"]
        #STDERR.puts deprel
        head = senthash["head"]
        upos = senthash["upos"]
        lemma = senthash["lemma"]
        #STDERR.puts upos
        feats = senthash["feats"]
        misc = senthash["misc"]
        form = senthash["form"]
        phrasecat = findinset(sent_id,"PhraseCat",	misc, sentence, id)
        #STDERR.puts "#{id}\t#{umisc[id].join(" ")}"
        udphrasecat = findinset(sent_id,"PhraseCat",umisc[id], sentence, id)
        #STDERR.puts "#{id}\t#{phrasecat}\t#{udphrasecat}"
        if udphrasecat.to_s != "" and udphrasecat != phrasecat
            phrasecat = udphrasecat.clone
        end
        #STDERR.puts "#{id}\t#{phrasecat}\t#{udphrasecat}"
        
        #if phrasecat == "KoP"
        #    @kopcounter += 1
        #end
    
       
        if head.nil?
            head = 0
        end
     

        if head == 0
            udeprels[id] = "root"
        end
        
        if ["MD","SB","OO","AG","IO","AN","OA","RA","EF","EO","ES"].include?(deprel)
            clause_or_not(phrasecat,upos,sent_id,id,deprel)
        end

=begin
        if !["case","mark","advmod","cconj","fixed","ME"].include?(deprel)
            if @markcats.include?(phrasecat) and ["VERB","AUX"].include?(upos)
                @clauses1 << "SM\t#{sent_id}\t#{id}"
            elsif  @markcats.include?(phrasecat) and !["VERB","AUX"].include?(upos)    
                @clauses1 << "S\t#{sent_id}\t#{id}"
            elsif !@markcats.include?(phrasecat) and ["VERB","AUX"].include?(upos)    
                @clauses1 << "M\t#{sent_id}\t#{id}"
            end
        end
=end
        
#converting DF
        if deprel == "DF"
            if lemma != "vilken"
                clause_or_not(phrasecat,upos,sent_id,id,"DF")
            end
            if upos == "CCONJ"
                udeprels[id] = "cc"
            elsif form == "osv" or form == "etc"
                udeprels[id] = "conj"
            elsif @markcats.include?(phrasecat) or upos == "VERB" #will NOT be corrected later by verbal_or_not
                udeprels[id] = "parataxis"
                
                
                #if phrasecat.to_s == ""
                #    STDOUT.puts "No PhraseCat\tDF\t#{sent_id}\t#{id}"
                #end
            else
                udeprels[id] = "discourse"
            end
        
        end

#converting DT
        if deprel == "DT"
            #STDERR.puts "DT! #{id}"
            if feats.include?("Poss=Yes") or feats.include?("Case=Gen") or upos == "NOUN" or upos == "PROPN" or upos == "X"#and form[-1]=="s") #because GEN is sometimes not marked on PROPNs, or because of constrs like Gustav Vasas or Gustav och Carls
                udeprels[id] = "nmod:poss"
            elsif upos == "ADJ"
                udeprels[id] = "amod"
            elsif upos == "ADV"
                udeprels[id] = "advmod"
            elsif upos == "NUM"
                udeprels[id] = "nummod"
            elsif upos == "DET"
                udeprels[id] = "det"				
            elsif sent_id == "Wiki_MiominMio.123"
                udeprels[id] = "nmod" #TODO
            else
                
                STDOUT.puts "DT, #{sent_id}, #{id}, #{upos}, #{form}"
            end
            #STDERR.puts "Result=#{udeprels[id]}"
        end

        
#converting MD        
        if deprel == "MD"
            if upos == "ADJ"
                udeprels[id] = "amod"
            elsif upos == "NOUN" or upos == "PROPN" or upos == "PRON" or upos == "X"
                udeprels[id] = "nmod"
            elsif upos == "NUM"
                udeprels[id] = "nummod"
            elsif upos == "ADV" or upos == "PART"
                udeprels[id] = "advmod"
            elsif upos == "VERB"
                udeprels[id] = "advcl"
            elsif upos == "ADP"
                if findinset(sent_id,"ExtXpos",misc,sentence, id)=="ABM"
                    udeprels[id] = "advmod"
                else
                    if ["VERB","ADJ"].include?(sentence[head]["pos"])
                        udeprels[id] = "obl" #TODO: Fix proper non-projective head for stranded prepositions using secedge. Obl correct if ellipsis
                    else
                        udeprels[id] = "nmod"
                    end
                    #STDOUT.puts "MD, #{sent_id}, #{id}, #{upos}, #{form}"    
                end
            elsif upos == "SCONJ" #fix SCONJs in general
                if @markcats.include?(phrasecat) #will be corrected later by verbal_or_not
                    udeprels[id] = "mark"
                else
                    udeprels[id] = "case"
                end
                #if phrasecat.to_s == ""
                #    STDOUT.puts "No PhraseCat\tSCONJ\t#{sent_id}\t#{id}"
                #end
            elsif upos == "INTJ" #fix? Arguably not INTJs?
                udeprels[id] = "advmod"
            elsif upos == "SYM"
                udeprels[id] = "advmod"
            elsif upos == "CCONJ"
                if ["dels","ju","ömsom"].include?(lemma) #TODO: ömsom treated differently in Talbanken, report?
                    udeprels[id] = "advmod"
                else
                    udeprels[id] = "cc" #TODO: fix så
                end
            else
                STDOUT.puts "MD, #{sent_id}, #{id}, #{upos}, #{form}"
            end
        end
        
#converting JF
        if deprel == "JF"
            #umisc[id] << "JF=True"
            
            clause_or_not(phrasecat,upos,sent_id,id,"JF")
            
            if verbal_or_not(sentence,id,["VERB","ADJ","ADV","AUX"]) #note that verbal_or_not is used differently, not as in mark/case (re)assignment below
                udeprels[id] = "advcl"
            else                
                udeprels[id] = "obl"
            end
            #STDOUT.puts "JF\t#{@copula}\t#{sent_id}\t#{upos}\t#{udeprels[id]}"
            #@jfuposs << upos
            #if ["NUM","INTJ","PRON","X"].include?(upos)
            #    STDOUT.puts "#{sent_id}\t#{upos}\t#{udeprels[id]}\tJF"
            #end
        
        end
    end
               
#depends on the udeprels assigned in the previous cycle, hence the new cycle. 
# double-checking mark and case and correcting everything else
    sentence.each_pair do |id,senthash|
        #STDERR.puts "#{id} #{senthash}"
        deprel = senthash["deprel"]
        #STDERR.puts deprel
        head = senthash["head"]
        upos = senthash["upos"]
        lemma = senthash["lemma"]
        #STDERR.puts upos
        feats = senthash["feats"]
        misc = senthash["misc"]
        form = senthash["form"]
        phrasecat = findinset(sent_id,"PhraseCat",	misc, sentence, id)
        udphrasecat = findinset(sent_id,"PhraseCat",umisc[id], sentence, id)
        if udphrasecat.to_s != "" and udphrasecat !=phrasecat
            phrasecat = udphrasecat
        end
        
        if head.nil?
            head = 0
        end
     

        if head == 0
            udeprels[id] = "root"
        end

        
        if udeprels[id] == "mark" or udeprels[id] == "case" or deprel == "mark" or deprel == "case"
            clause_or_not(phrasecat,upos,sent_id,head,"markcase")
            if udeprels[id] == "mark" or udeprels[id] == "case" #at this point, mark/case could have been specified either in deprel or in udeprel, hence the weird structure
                old = udeprels[id].clone
            else
                old = deprel.clone
            end
           
            if verbal_or_not(sentence,head,["VERB","AUX"]) #the @markcats approach overgenerates "mark", because Eukalyptus is much more generous with subordinate phrases/clauses than UD. Hence another rule: if the head is not verbal, ignore PhraseCat
                if !@copula #exception: if the head is nominal and there is a copula as a daughter, it COULD be a clause, but too many examples aren't (additional problem: too many "vara" misclassified as copula. Best to ignore such cases
                    udeprels[id] = "mark"
                else
                    if udeprels[id].nil? #that's just for debugging purposes, otherwise missing udeprels could be dealt with below              
                        udeprels[id] = deprel.clone
                    end
                end
            else
                if udeprels[head] != "advcl"
                    udeprels[id] = "case" #works quite well
                else
                    udeprels[id] = "mark"               
                end
            end            
            #if udeprels[id] != old #== "mark" and old == "case" #
                #STDOUT.puts "CHANGE\tcopula=#{@copula}\t#{sent_id}\t#{id}\tchange #{old} to #{udeprels[id]}"
            #end
        
        end
        
#converting -- to punct
        if upos == "PUNCT"
            udeprels[id] = "punct"
        #elsif deprel.downcase == deprel
        #    udeprels[id] = deprel
        else           
#converting everything else via the one-to-one list        
            if !@matchdeprels[deprel].nil? and udeprels[id].nil?
                udeprels[id] = @matchdeprels[deprel]
            else
#catching those that already were converted but did not make it to udeprels[id]
                if udeprels[id].nil?
                    udeprels[id] = deprel
                end
            end
        end
        uheads[id] = head #move to a separate cycle?
        miscarray = misc.split("|")
        
        #to prevent tokens having two PhraseCat (can happen with former functional heads)
        if miscarray.select{|s| s.include?("PhraseCat")}.length > 0 and umisc[id].select{|s| s.include?("PhraseCat")}.length > 0
            miscarray.reject! {|s| s.include?("PhraseCat")}
        end
        
        
        umisc[id] = [umisc[id],miscarray].flatten.sort.join("|")
        #if umisc[id].nil?
        #    umisc[id] = misc
        #end


        #START WITH HASH
    end
    
    return uheads, udeprels, umisc
end

def findinset(sent_id,target,misc,sentence,id)
    if misc.kind_of?(Array)
        miscs = misc.clone
    else 
        miscs = misc.to_s.split("|")
    end
    value = nil
    miscs.each do |miscs1|
        if miscs1.include?(target)
            value = miscs1.split("=")[1]
            break
        end
    end
    #if target == "PhraseCat" and value == "KoP"
    #    STDOUT.puts "#{sent_id},#{id}"
    #end
    return value
end

def convert(id, sentence, sent_id)
    #STDERR.puts "convert: #{sentence}"
    form,lemma,pos,msd,msd2,head,deprel,enhdep,misc = getinfofromsentence(sentence,id)
    

    firsttoken = sentence.keys.min
        
    if !@lemmacorrections[lemma].nil?
        
        lemma = @lemmacorrections[lemma]
        #STDERR.puts "#{sent_id} #{lemma}"
        sentence[id]["lemma"] = lemma.clone
    end
    

    if ["inte","icke","ej"].include?(form.downcase)
        upos = "PART"
    end

    if "att" == form.downcase
        if !sentence[id+1].nil?
            if sentence[id+1]["pos"] == "VB" and sentence[id+1]["msd"].include?("INF")
                upos = "PART"
            else
                upos = "SCONJ"
            end
        else
            STDOUT.puts "#{sent_id} att at the end of a sentence"
        end
    end   
 


    

    if pos == "SY"
        if msd.include?("DEL")
            upos = "PUNCT"
        else
            upos = "SYM"
        end
    end

    if upos.nil?
        upos, lemma = adverbials(id, sentence, sent_id)
    end

    if pos == "PE"
        daughters = finddaughters(sentence,id)
        if deprel == "PL" or @adpnotadv.include?(lemma) #1) for now, I am preserving the Euk classification of "particles", since the UD one is inconsistent 2) a rather barbaric way to avoid overproduction of ADV
            prepflag = true
        else
            prepflag = false
            daughters.each do |daughter|
                if sentence[daughter]["deprel"] == "OO" or sentence[daughter]["deprel"] == "ME" or sentence[daughter]["deprel"] == "MD" #remove the ME condition?
                    if lemma == "över"
                        if sentence[daughter]["pos"] == "NU"
                            
                            break
                        else
                            overflag = true
                            granddaughters = finddaughters(sentence,daughter)
                            granddaughters.each do |granddaughter|
                                if sentence[daughter]["pos"] == "NU"
                                    overflag = false
                                    break
                                end
                            end
                            if overflag
                                prepflag = true
                            end
                            break
                        end
                    else
                        prepflag = true
                        break
                    end
                end
            end
        end
        if prepflag 
            upos = "ADP"
        else
            upos = "ADV"
        end

    end


    if deprel == "DT" #TODO: overproduction of DET
        if @determiners.include?(lemma)
            upos = "DET"
        elsif lemma == "samtlig" or lemma == "varsin"
            upos = "ADJ"
        end
    end
    
    if lemma == "mycket" or lemma == "mycken" or lemma == "litet" or lemma == "mången" or lemma == "många" or lemma == "flera"
        if deprel == "DT"
            upos = "ADJ"
            msd.delete("IND")
            msd.delete("SIN")
            msd.delete("NEU")
            if !msd.include?("KOM") and !msd.include?("SUV")
                msd << "POS"
            end
        elsif deprel == "MD"
            upos = "ADV"
            msd.delete("IND")
            msd.delete("SIN")
            msd.delete("NEU")
            if !msd.include?("KOM") and !msd.include?("SUV")
                msd << "POS"
            end
        else
            upos = "PRON"
        end
        if !@mycketlemmas[lemma].nil? 
            lemma = @mycketlemmas[lemma]
        end
        
    end
    
    
    if upos.nil?
        upos = @matchingu[pos]
    end

    if !@uposcorrections[lemma].nil? 
        upos = @uposcorrections[lemma]
    end

    feats = []
    partresults = detectparticiple(pos,upos,lemma,head,deprel,sentence,sent_id,"toud") 
    feats << partresults[1]
    feats.flatten!
    upos = partresults[0]

    if pos == "VB"
        #DIM: AUX vs VERB add "det" disambiguation
        #DIM: AUX vs VERB add "vara" disambiguation
        if @auxlist.include?(lemma)
            auxflag = false
            daughters = finddaughters(sentence,id)
            if lemma == "bli"
                daughters.each do |daughter|
                    daughterupos,daughterfeats = detectparticiple(sentence[daughter]["pos"],"",sentence[daughter]["lemma"],sentence[daughter]["head"],sentence[daughter]["deprel"],sentence,sent_id,"toud")
                    if daughterfeats.include?("VerbForm=Part") and daughterfeats.include?("Tense=Past") and sentence[daughter]["deprel"] == "SP"
                        auxflag = true
                        break
                    end
                end
            elsif lemma == "ha"
                daughters.each do |daughter|
                    #STDERR.puts daughter
                    #if !sentence[daughter]["msd"].include?("SPM") and sentence[daughter]["deprel"] == "IV"
                        #STDERR.puts "#{sent_id} #{daughter}"
                    #end

                    if sentence[daughter]["deprel"] == "IV" and sentence[daughter]["form"] != "att" #cf. Wiki_VascodaGama.39
                        auxflag = true
                        break
                    end
                end
            elsif lemma == "vara"
                daughters.each do |daughter|
                    if sentence[daughter]["deprel"] == "SP"
                        auxflag = true
                        break
                    end
                end
            else
                daughters.each do |daughter|
                    #if ((sentence[daughter]["msd"].include?("INF") or sentence[daughter]["lemma"] == "att")) or (sentence[daughter]["msd"].include?("SPM")) and sentence[daughter]["deprel"] == "IV"
                    if sentence[daughter]["deprel"] == "IV"
                        if lemma == "få" and sentence[daughter]["lemma"] == "att"
                            auxflag = false
                        else
                            auxflag = true
                        end
                        break
                    end
                end
            end
            if auxflag
                upos = "AUX"
            end
        end
    end

    msd.each do |msdunit|
        if pos == "VB"
            relevant_feats = @matchvbfeats.clone
        else
            relevant_feats = @matchfeats.clone
        end

        if !relevant_feats[msdunit].nil?
            #if !(upos == "ADV" and (relevant_feats[msdunit].include?("Definite") or relevant_feats[msdunit.include?("Number") or relevant_feats[msdunit].include?("Gender"))
            feats << "#{relevant_feats[msdunit]}"
            
        end
    end

    if ["NOUN","PROPN","ADJ"].include?(upos)
        if msd2[1] == "GEN"
            feats << "Case=Gen"
        else
            feats << "Case=Nom"
        end
    end
    
    if upos == "PRON"
       if msd2[1] == "GEN"
           feats.delete("Case=Acc")
           feats << "Poss=Yes"
       end
       if lemma == "vars"
           feats.delete("Definite=Ind")
           feats << "Definite=Def"
           feats << "Poss=Yes"
       end
    
    end

    if upos == "PRON" or upos == "DET"
        if !@posslemmas[lemma].nil?
            lemma = @posslemmas[lemma]
        end

        if (lemma == "de" or lemma == "den") and upos == "PRON"
            prontype = "Prs"
        elsif (lemma == "de" or lemma == "den") and upos == "DET"
            prontype = "Art"
        else
            prontype = @prontypes[lemma]
        end
        if prontype == "" or prontype.nil?
            STDOUT.puts "Unknown prontype! #{lemma} #{sent_id}"
        else
            feats << "PronType=#{prontype}"
        end
    end

    if upos == "VERB" and !feats.join.include?("VerbForm")
        feats << "VerbForm=Fin"
    end

    if pos == "UO"
        feats << "Foreign=Yes"
    end
    if upos == "PART" and (lemma == "inte" or lemma == "icke" or lemma == "ej")
        feats << "Polarity=Neg"
    end    

    if pos == "VB"
        if feats.include?("Voice=Pass") 
            if lemma[-1] == "s" 
                feats.delete("Voice=Pass")
            elsif @nonsfolemmas.include?(lemma)
                feats.delete("Voice=Pass")
                lemma = "#{lemma}s"
            end
        end
            
        if lemma == "må"
            if feats.include?("Mood=Sub")
                feats.delete("Mood=Sub")
                feats << "Mood=Ind"
            end
        end
    end

    if form.downcase == "vare" and sentence[id+1]["form"].downcase == "sig" and sentence[id-1]["form"].to_s.downcase != "tack"
        lemma = "vare"
        upos = "CCONJ"
        feats = []
    end

    if lemma == "ju"
        if head > id
            upos = "CCONJ"
            feats = []
        end
    end

    if ["ömsom","dels"].include?(lemma)
        upos = "CCONJ"
        feats = []
    end

    if form.downcase[-1] == "s" and form.downcase == "#{lemma.downcase}s" and id > 1
        if sentence[id-1]["lemma"] == "till"
            feats.delete("Case=Nom")
            feats << "Case=Gen"
        end
    end

    if pos == "NU" #and form.downcase != lemma.downcase
        lemma = form.clone
        feats << "NumType=Card"
        #STDOUT.puts "#{form}\t#{lemma}"
    end

    if upos == "ADJ" and @ordnums.include?(lemma.downcase)
        feats << "NumType=Ord"
    end


    if msd2.include?("FKN")
        feats << "Abbr=Yes"
    end

    if misc.include?("CorrectForm")
        feats << "Typo=Yes"
    end

    feats = feats.uniq.sort.join("|")
    if feats == ""
        feats = "_"
    end

    if upos != "PUNCT" and upos != "SYM"
        lemma.gsub!("|","")
        lemma.gsub!("<","")
    end

    if lemma == "_" or lemma == ""
        lemma = form.clone
    end

    lemma.gsub!(" ","_")

    if upos == "" or upos.nil? or !@all_upos.include?(upos)
        STDOUT.puts "Invalid UPOS=#{upos} #{lemma} #{id} #{sent_id}"
    end
        
    return upos, feats, lemma
end


output = []
output_synt = []
sentence = {}
sentence_pos_converted = {}
sent_id = ""
dtlist = []

def output_sentence(sentence)
    sentence.each_pair do |id, senthash|
        STDERR.puts "#{id}\t#{senthash}"
    end
end

inputfile.each_line do |line|
    line1 = line.strip
    if line1 != ""
        if line1[0] == "#"
            if mode == "convert"
                output << line1
                #output_synt << line
            end
            if line1.include?("sent_id")
                sent_id = line1.split(" = ")[1]
                #STDERR.puts sent_id
            end
        else
            line2 = line1.split("\t")
            id = line2[0].to_i
            form = line2[1]
            lemma = line2[2].gsub("|","")
            pos = line2[3]
            msd2 = line2[4].split(".")
            msd = line2[5].split(".")[1..-1]
            head = line2[6].to_i
            deprel = line2[7]
            enhdep = line2[8]
            misc = line2[9].to_s
            if mode == "list_pos"
                if pos == ref_pos
                    #lemmas_per_pos[pos][lemma] = true
                    if lemma != "_"
                        lemmas_per_pos[lemma] = true
                    else
                        lemmas_per_pos[form] = true
                    end
                end
            end

            if mode == "convert"
                sentence[id] = {"form"=>form,"msd"=>msd,"msd2"=>msd2,"head"=>head,"deprel"=>deprel,"lemma"=>lemma, "enhdep"=>enhdep, "misc"=> misc, "pos" => pos} 
            end
            #STDERR.puts sentence[id]["head"]

            if mode == "other"
                if pos == "PO" and deprel == "DT" and !dtlist.include?(lemma)
                    dtlist << lemma
                end
            end
            
        end
    else
        if mode == "convert"
            sentence = convert_coordination(sentence,sent_id)
            #output_sentence(sentence)
            sentence_pos_converted = sentence.clone
            #STDERR.puts sentence
            #STDERR.puts ""
            
            sentence.each_pair do |id,senthash|
                upos, feats, lemma = convert(id, sentence, sent_id)
                #STDERR.puts "#{id} #{upos}"
                line3 = [id, senthash["form"], lemma, upos, "_", feats, senthash["head"], senthash["deprel"], senthash["enhdep"], senthash["misc"]].join("\t")
                output << line3

                sentence_pos_converted[id]["lemma"] = lemma
                sentence_pos_converted[id]["upos"] = upos
                sentence_pos_converted[id]["feats"] = feats


                if list_out_pos
                    if senthash["lemma"] != "_"
                        lemma_per_pos2[upos] << senthash["lemma"]
                    else
                        lemma_per_pos2[upos] << senthash["form"]
                    end
                end
            end
            
            sentence_pos_converted = sentence.clone
            
            STDERR.puts sent_id
            uheads, udeprels, umisc = convert_syntax(sentence_pos_converted, sent_id)
            #STDERR.puts "#{uheads}"
            #STDERR.puts "#{udeprels}"
            

            output.each do |outputline|
                outputline1 = outputline.strip
                if outputline1[0] == "#"
                    output_synt << outputline1
                else
                    outputline2 = outputline1.split("\t")
                    id = outputline2[0].to_i
                    misc = umisc[id]#.to_s.split("|").sort.join("|")
                    outputline_synt = [id, outputline2[1], sentence[id]["lemma"], sentence[id]["upos"], outputline2[4], outputline2[5], uheads[id],udeprels[id],outputline2[8],misc].join("\t")
                    output_synt << outputline_synt
                end
            end
            
            outputfile_pos.puts output
            outputfile_pos.puts ""
            outputfile_syntax.puts output_synt
            outputfile_syntax.puts ""
            
            output = []
            output_synt = []
            sentence = {}
            sentence_pos_converted = {}
        end
    end
end

if mode == "list_pos"
    lemmas_per_pos.each_key do |lemma|
        pos_outputfile.puts lemma
    end
end

if list_out_pos
    outpos = File.open("outposs.tsv","w:utf-8")
    lemma_per_pos2.each_pair do |upos,lemmas|
        outpos.puts "#{upos}\t#{lemmas.uniq.join("\t")}"
    end
end

if mode == "other"
    STDERR.puts dtlist
end

STDOUT.puts ""
@clauses1.each_pair do |deprel,examples|
    STDOUT.puts examples.shuffle
end

#STDOUT.puts @chain_array.uniq
#STDERR.puts @jfuposs.uniq