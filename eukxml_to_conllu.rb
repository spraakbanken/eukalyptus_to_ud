require 'io/console'

# reverse head-dependent for content words
# coordination


#? Decide the systematic way to deal with coordination (## multiple heads in coordination?)

#check labels in general and heads of MWEs in particular (currently just inheriting head node automatically, should be OK) 
#check if we need @reversed_labels2 (yes we do for 17 and 34, but what do we actually want for them?), check if labels for MWE non-heads are OK
#Check Romn_Lundqvist-Ingentobak.45: HD in secondary edges

#?: do embedded *Ms exist? Yes: Romn_Holmsen-Polynesiskpassad.102 and 376. Are they correct, though?
#the third type of MWEs: seems to be OK?

#questions to Gerlof that are already sent

#17 and 34 fixed by dispreferring PH-roots: but is it reliable?
#headless: treat more systematically depending on type? (NPs)
## other stragegies: use first, use root, go down? Maybe not needed?

#TODO2: Romn_Bjelvehammar-TageBengtsson.241


verbose = ARGV[0]
if verbose.nil? or verbose == "false"
    verbose = false
end

require "Nokogiri"

def nodeid_to_integer(sent_id,node_id)
    #STDERR.puts "..#{node_id}"
    if node_id.nil?
        id = "9999"
    #elsif node_id != 0 #uncomment if the optimized conversion doesn't work
        #id = node_id.gsub("#{sent_id}.","") #uncomment if the optimized conversion doesn't work
        
    else
        id = node_id
    end
    return id
end

#def nodeid_to_integer2(node_id)
     
#end

def one_termid_to_integer(term_id, mapping)
    
    if mapping[term_id].nil?
        out_id = term_id.clone
    else
        out_id = mapping[term_id]
    end
    return out_id
end

def alltermids_to_integer(term_ids)
    term_ids2 = []
    mapping = {}
    term_ids.each.with_index do |old_id,index|
        mapping[old_id] = index+1
        term_ids2 << index+1
    end

    return term_ids2,mapping
end

def reassign_mwe_heads(mwe,head,term_ids,primary_tree,node)
    mwe.each.with_index do |mwenode, mwenodeindex|
        if mwenode != head
            if term_ids.include?(mwenode)
                @reversed_tree[mwenode] = head #next_level[head_label_index]
                @reversed_labels[mwenode] = @primary_labels[node][mwenodeindex]
            else
                reassign_mwe_heads(primary_tree[mwenode],head,term_ids,primary_tree,node)
            end
        end
    end                          
end
                                


def deal_with_mwes(primary_tree, current_id, phrases, term_ids, words, verbose, sent_id)
    if verbose then STDERR.puts "New method" end
    until false == true do
        next_level = primary_tree[current_id]
        if verbose then STDERR.puts "Current_id: #{current_id}" end
        if verbose then STDERR.puts "Current_id: #{current_id} Next level: #{next_level}" end
        #STDIN.getch
        next_level.each.with_index do |node,nodeindex|
            if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node}" end
            if !term_ids.include?(node)
                if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal" end
                cat = phrases[node]
                #STDIN.getch
                if cat[2] == "M" #MWE
                    if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE" end
                    #STDIN.getch
                    mwe = primary_tree[node].clone
                    if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE #{mwe}" end
                    if mwe.length > 1 #non_analyzable
                        head = nil
                        mwe.each do |mwenode|
                            if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE Non-analyzable Looking for head" end
                            if words[mwenode]["pos"] == cat[0..1]
                                #flag = true
                                head = mwenode.clone
                                if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE Non-analyzable Head #{head}" end
                                break
                            end
                        end
                        if head.nil? #assign head even if there was no pos match
                            mwe.each do |mwenode|
                                if term_ids.include?(mwenode)
                                    head = mwenode.clone
                                end
                            end
                            if head.nil?
                                STDERR.puts "ERROR ERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERROR MWE head not found!"
                            end

                            #head = mwe[0].clone
                            if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE Non-analyzable No real head found, taking the leftmost terminal node as head #{head}" end
                        end
                        
                        if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE Restructuring the tree" end
                                
                        #@primary_tree[current_id] << head
                        #@primary_labels[current_id][nodeindex] = @primary_labels[node].clone
                        
                        #@reversed_labels[head] = @primary_labels[node].clone
                        #@primary_tree[head] = []
                        #change labels, too
                        if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE Reassigning heads" end                            
                        reassign_mwe_heads(mwe,head,term_ids,primary_tree,node)
=begin
                        mwe.each.with_index do |mwenode, mwenodeindex|
                            if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE Reassigning heads" end
                            

                            if mwenode != head
                                #@primary_tree[head] << mwenode
                                if term_ids.include?(mwenode)
                                    @reversed_tree[mwenode] = head #next_level[head_label_index]
                                    #@reversed_labels[mwenode] = "HD-#{cat}"
                                    @reversed_labels[mwenode] = @primary_labels[node][mwenodeindex]
                                else
                                    nodesundermwe = primary_tree[mwenode]
                                    nodesundermwe.each.with_index do |nodesundermwenode, nodesundermwenodeindex|
                                        if term_ids.include?(nodesundermwenode)
                                            @reversed_tree[nodesundermwenode] = head #next_level[head_label_index]
                                            #@reversed_labels[mwenode] = "HD-#{cat}"
                                            @reversed_labels[nodesundermwenode] = @primary_labels[nodesundermwenode][nodesundermwenodeindex]
                                        else
                                            for i in 1..10
                                                STDERR.puts "RECURSION required #{sent_id}"
                                            end
                                        end
                                    end
                                end
                            end
                        end
=end
                    else
                        head = mwe[0].clone
                        if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal MWE Analyzable. Head: #{head}" end
                    end
                    @primary_tree[current_id][nodeindex] = head.clone
                    @primary_tree.delete(node)
                    if verbose then STDERR.puts "#{@primary_tree}" end
                    if verbose then STDERR.puts "#{@reversed_tree}" end
                    @mwes_replaced[node] = head.clone
                else
                    if verbose then STDERR.puts "Current_id: #{current_id} Node: #{node} Nonterminal Usual" end
                    #STDIN.getch
                    
                end
                deal_with_mwes(primary_tree, node, phrases, term_ids, words, verbose, sent_id)
                
            end
        end
        if verbose then STDERR.puts "Current_id: #{current_id} Going up" end
        break
    end
end

def process_primary_tree(primary_tree, primary_labels, current_id, term_ids, phrases, root, sent_id, phraselabel,verbose,words)
    #current_id = "#{sent_id}.0"
    #root = 0
    cat = phrases[current_id]
    #STDERR.puts "current_id", current_id
    #gets
    
    if verbose then STDERR.puts "Current_id: #{current_id}" end
    #STDERR.puts "*** #{primary_tree["Romn_Lundqvist-Ingentobak.20.5"]} ***"
    onlyterminalsontop = false    
    discourseterminalontop = {}
    


    until false == true do
        next_level = primary_tree[current_id]
        if verbose then STDERR.puts "Current_id: #{current_id} Next level: #{next_level}" end
        labels = primary_labels[current_id]
        head_label_index = labels.index("HD") 

        
  
        #assign heads and do some more
        if cat == "Top"
            #root = 0
            if verbose then STDERR.puts "Current_id: #{current_id} Cat: #{cat}" end

            if next_level.length > 1
                if verbose then STDERR.puts "Current_id: #{current_id} Several nodes under Top. Check if they all are terminal" end
    
                nonterminals = 0
                nonterminal_cats = []
                terminal_nonsy_list = []

                #next_level.each do |node|
                #    if !term_ids.include?(node)
                #        nonterminals += 1
                #        nonterminal_cats << phrases[node]
                #    end
                #end
                #if nonterminals > 1
                #    @nsents_several_nonterminals_on_top += 1
                #    #STDOUT.puts "#{sent_id}\t#{nonterminals}\t#{nonterminal_cats.uniq}\t#{nonterminal_cats}"
                #end

                terminalsonly = 1
                
                nonsymbols = 0
                the_nonsymbol = nil
                #if next_level.length > 1
                    
                next_level.each do |node|
                    if !term_ids.include?(node)
                        if verbose then STDERR.puts "Current_id: #{current_id} There is a non-terminal node #{node}, we are fine" end
                        nonterminals += 1
                        nonterminal_cats << phrases[node]
                        terminalsonly = 0
                        #break
                    else
                        if words[node]["pos"] != "SY"
                            nonsymbols += 1
                            the_nonsymbol = node.clone
                            terminal_nonsy_list << node
                        end
                    end
                end

                if nonterminals > 1
                    @nsents_several_nonterminals_on_top += 1
                    @sentids_several_nonterminals_on_top << sent_id
                    #if nonterminal_cats.uniq == ["KoP"] or nonterminal_cats.uniq.sort == ["KoP", "SuP"]
                    #    STDOUT.puts sent_id
                    #end
                    #STDOUT.puts "#{sent_id}\t#{nonterminals}\t#{nonterminal_cats.sort.uniq}\t#{nonterminal_cats.sort}"
                    combination = nonterminal_cats.sort.uniq.join(", ")
                    @cat_combinations_on_top[combination]+=1
                    if combination.include?("S") or combination.include?("KoP") or combination.include?("SuP") or combination.include?("VP")
                        @nonterminallinkontop = "parataxis"
                    else
                        @nonterminallinkontop = "conj"
                    end
                    
                    
                end

                
    
                #end
                
                if terminalsonly == 1 
                    if verbose then STDERR.puts "Current_id: #{current_id} All nodes under Top are terminal, we have to assign a head" end
    
                    if nonsymbols == 1
                        if verbose then STDERR.puts "Current_id: #{current_id} There is only one node which is not a SY, choose it as a head" end
    
                        head = the_nonsymbol.clone
                        onlyterminalsontop = true
                    elsif nonsymbols == 0
                        if verbose then STDERR.puts "Current_id: #{current_id} There are no nodes which are not a SY, choose the first node as a head" end
    
                        head = term_ids[0].clone
                        onlyterminalsontop = true
                    else #nonsymbols != 1 #and next_level.length > 1
                        if verbose then STDERR.puts "Current_id: #{current_id} There are more than one nodes which are not a SY, currently no heuristics to choose a head. STDOUT an exception" end
                        #STDERR.puts "Sent_id: #{sent_id} Current_id: #{current_id} There are more than one nodes which are not a SY, currently no heuristics to choose a head. STDOUT an exception"

=begin
                        if verbose then STDERR.puts "Current_id: #{current_id} Checking if there are several KoPs" en
                        possible_heads_from_kops = []
                        next_level.each.with_index do |node, nodeindex|
                            if !term_ids.include?(node)
                                next_level_cat = phrases[node]
                                

                                if next_level_cat == "KoP"
                                    next_level_labels = primary_labels[node]
                                    if !labels.index("HD").nil?
                                        possible_heads_from_kops << labels.index("HD")
                                    elsif !labels.index("PH").nil?
                                        possible_heads_from_kops << labels.index("PH")
                                    end
                                end
                                
                                #STDERR.puts "Current_id: #{current_id} FIRST NODE AS HEAD #{head}"
                                break
                            end
                        end
                        if possible_heads_from_kops.length > 0
                            head = possible_heads_from_kops.length.sort[0]
                        end
=end                        
                        @n_only_terminals_on_top += terminalsonly
                        #STDOUT.puts "#{sent_id}\t#{nonsymbols}"
                        #end
                    end
                else
                    if nonsymbols > 0
                        terminal_nonsy_list.each do |terminal_nonsy|
                            discourseterminalontop[terminal_nonsy] = true
                        end
                        #Sentences where there are non-terminals on top, but also non-SY terminals
                        #STDOUT.puts "#{sent_id}\t#{nonsymbols}"
                    end
                end
            end
        else
            if verbose then STDERR.puts "Current_id: #{current_id} Cat: #{cat}" end
            head_label_index = labels.index("HD") 
            
            if head_label_index.nil?
                head_label_index = labels.index("PH")
            else
                if verbose then STDERR.puts "Current_id: #{current_id} HD found: #{next_level[head_label_index]}" end
            end
            if !head_label_index.nil?
                if verbose then STDERR.puts "Current_id: #{current_id} HD or PH found: #{next_level[head_label_index]}" end
                temphead = next_level[head_label_index].clone
                if term_ids.include?(temphead)
                    head = temphead.clone
                    if verbose then STDERR.puts "Current_id: #{current_id} HD or PH confirmed as terminal: #{next_level[head_label_index]}" end
                else
                    if verbose then STDERR.puts "Current_id: #{current_id} HD or PH erased: non-terminal" end
                    head_label_index = nil
                end
            else
                if verbose then STDERR.puts "Current_id: #{current_id} No HD or PH found" end
            end
            if head_label_index.nil?
                head_candidates = []
                candidate_index = {}
                #head_old = nil
                #head_label_index_old = nil
                if verbose then STDERR.puts "Current_id: #{current_id} Assigning the leftmost node as a head" end
                #next_level.each.with_index do |node, nodeindex|
                #    if term_ids.include?(node)
                 
                #        head_old = node.clone
                #        head_label_index_old = nodeindex
                #        if verbose then STDERR.puts "Current_id: #{current_id} Assigned first node as a head: #{head}" end
                        #STDERR.puts "Current_id: #{current_id} FIRST NODE AS HEAD #{head}"
                #        break
                #    end
                #end
                next_level.each.with_index do |node, nodeindex|
                    if term_ids.include?(node)
                        head_candidates << node
                        candidate_index[node] = nodeindex
                    end
                end
                head = head_candidates.min
                head_label_index = candidate_index[head]
                if verbose then STDERR.puts "Current_id: #{current_id} Assigned the leftmost node as a head: #{head}" end
                #STDOUT.puts "Current_id: #{current_id} Assigned the leftmost node as a head: #{head}"
                #if head_old != head
                #    STDOUT.puts "#{sent_id}\t#{head}\t#{head_old}"
                #end
                

                if head_label_index.nil?
                    if verbose then STDERR.puts "Current_id: #{current_id} No first node found. Assigning root #{root} as head" end
                    head = root.clone
                    #STDERR.puts "Current_id: #{current_id} ROOT AS HEAD #{head}"
                    #abort
                end
            end
        end
        



        @head_by_nt[current_id] = head.clone
        if verbose then STDERR.puts "  Current_id: #{current_id} Root: #{root}" end
        if verbose then STDERR.puts "  Current_id: #{current_id} Head: #{head}" end
        #if verbose then STDERR.puts "Next level: #{next_level}" end


        next_level.each.with_index do |node,nodeindex|
            if verbose then STDERR.puts "  Current_id: #{current_id}. Terminal run. Node: #{node}" end
            if term_ids.include?(node)
                if verbose then STDERR.puts "    head == root Current_id: #{current_id}. Node: #{node}. Terminal node" end
                if cat == "Top" and onlyterminalsontop == false #and head == root #head.nil?#root == 0
                    if verbose then STDERR.puts "    Current_id: #{current_id}. Terminal under 0" end
                    #@reversed_tree[node] = root
                    if discourseterminalontop[node] == true
                        @reversed_labels[node] = "discourse"
                    #elsif @nonterminallinkontop != false
                    #    @reversed_labels[node] = @nonterminallinkontop.clone
                    else
                        @reversed_labels[node] = labels[nodeindex]
                    end
                    @underoldroot[node] = true
                    
                else
                    #if verbose then STDERR.puts "    Current_id: #{current_id}. Terminal not under 0" end
                    

                    if node == head #nodeindex == head_label_index
                        
                        if root == 0 and @newroot.nil? # and cat != "KoP"
                            if verbose then STDERR.puts "    Current_id: #{current_id}. New root!" end
                            @newroot = node.clone#.gsub("#{sent_id}.","").to_i
                        end
                        if verbose then STDERR.puts "    Current_id: #{current_id}. Phrase head" end
                        if verbose then STDERR.puts "    Current_id: #{current_id}. Ends up under ('root') #{root}" end
                        #if root == 0
                        #    @rootlist << node
                        #end
 

                        @reversed_tree[node] = root
                        if root == 0
                            @under0 << node
                        end
                        #root = node.gsub("#{sent_id}.","").to_i
                        @reversed_labels[node] = phraselabel #"#{labels[nodeindex]}-#{cat}-#{phraselabel}"
                        @reversed_labels2[node] = "#{labels[nodeindex]}-#{cat}-#{phraselabel}"
                    else
                        if verbose then STDERR.puts "    Current_id: #{current_id}. Not a head" end
                        if verbose then STDERR.puts "    Current_id: #{current_id}. Ends up under ('head') #{head}" end
                        @reversed_tree[node] = head #next_level[head_label_index]
                        @reversed_labels[node] = labels[nodeindex]
                    end
                end
            end
        end
        #if verbose then STDERR.puts "Next level: #{next_level}" end
       
        next_level.each.with_index do |node,nodeindex|
            if verbose then STDERR.puts "  Current_id: #{current_id}. Nonterminal run. Node: #{node}" end
            if !term_ids.include?(node)
                if verbose then STDERR.puts "    Current_id: #{current_id}. Node: #{node}. Nonterminal node" end
                #root = current_id.gsub("#{sent_id}.","").to_i
                if cat != "Top" #!head.nil?
                    root = head.clone#.gsub("#{sent_id}.","").to_i
                end
                phraselabel = labels[nodeindex]

                #if root != 0
                #    root = next_level[head_label_index].gsub("#{sent_id}.","").to_i
                #end
                if verbose then STDERR.puts "    Current_id: #{current_id}. Going down. Root #{root}" end
                process_primary_tree(primary_tree, primary_labels, node, term_ids, phrases, root, sent_id, phraselabel,verbose,words)
            end
        end



        if verbose then STDERR.puts "    Current_id: #{current_id}. Going up" end
        break
    end 
    
    return root#[reversed_tree,reversed_labels]
end


def go_up(reversed_tree,id,passed_nodes)
    #STDERR.puts id
    if id == 0
        
        return
    else
        head = reversed_tree[id]
        passed_nodes << id
        

        if head == 0 or @safe_nodes.include?(id)
            return
        elsif head.nil? #preventing disconnected branches
            @status = "disconnected"
            @disconnected_ids << id
            return
        elsif passed_nodes.include?(head) #preventing cycles
            @status = "cycle"
            return
        else
            @safe_nodes << id
            go_up(reversed_tree,head,passed_nodes)
        end
    end
end

def check_reversed_tree(reversed_tree)
    nheads = reversed_tree.select{|key, value| value == 0 }.keys.length
    @status = "ok"
    @safe_nodes = []
    reversed_tree.keys.each do |node|
        #STDERR.puts "going up"
        if !@safe_nodes.include?(node)
            go_up(reversed_tree,node,[])
            @safe_nodes.uniq!
        end
    end

    if nheads == 1 and @status == "ok"
        status = 0 
    else
        status = 1
    end
    return [status,nheads,@status]
end


PATH = "C:\\Sasha\\D\\DGU\\Repos\\Eukalyptus-dev\\Annotations\\"
#PATH = "C:\\Sasha\\D\\DGU\\SBX_resources\\Eukalyptus-1.0.0\\Annotations\\"
#PATH = "D:\\DGU\\SBX_resources\\Eukalyptus\\Eukalyptus-1.0.0\\Annotations\\"



#filename = ARGV[0]
#outputfile = File.open("#{filename}.conllu","w:utf-8")



if !ARGV[1].nil?
    outputfile = File.open("test0.conllu","w:utf-8")
    filenames = ["test0"]
    tree_error_file = File.open("ill-formed_trees_test.txt","w:utf-8")
else
    outputfile = File.open("eukalyptus_all.conllu","w:utf-8")
    filenames = ["Eukalyptus_Blogg","Eukalyptus_Europarl","Eukalyptus_Nyhetstext","Eukalyptus_Romaner","Eukalyptus_Wikipedia"]
    tree_error_file = File.open("ill-formed_trees.txt","w:utf-8")
end


excluded_sents = {}
n_processed_sents = 0
@nsents_several_nonterminals_on_top = 0
@sentids_several_nonterminals_on_top = []
@cat_combinations_on_top = Hash.new(0)
@n_only_terminals_on_top = 0
n_wrong_trees = 0


undercounter = 0
filenames.each do |filename|
    
    STDERR.puts "Parsing xml..."
    file = Nokogiri::XML(File.read("#{PATH}#{filename}.xml"))
    STDERR.puts "Looking for subcorpora..."
    subcorpora = file.css("subcorpus").to_a
    #excluded_sents = {"Romn_Holmsen-Polynesiskpassad.102" => true, "Romn_Holmsen-Polynesiskpassad.376" => true}
    
    #prev_subcorpus_id = ""
    #subcorpus_id = ""
    
    
    subcorpora.each do |subcorpus|
        
        subcorpus_id = subcorpus["name"]
        if filename.include?("Nyhet")
            subcorpus_id = "News_#{subcorpus_id}"
        end
        #if subcorpus_id != prev_subcorpus_id
        #    newdoc = true
        #end
        
        STDERR.puts subcorpus_id
        sentences = subcorpus.css("s").to_a
        sentences.each.with_index do |sentence,sentnumber|
            primary_tree = Hash.new{|hash, key| hash[key] = Array.new}
            primary_labels = Hash.new{|hash, key| hash[key] = Array.new}
            secondary_tree = Hash.new{|hash, key| hash[key] = Array.new}
            secondary_labels = Hash.new{|hash, key| hash[key] = Array.new}
            sent_id = sentence["id"]
            if !excluded_sents[sent_id]
                #STDERR.puts sent_id
                words = Hash.new{|hash, key| hash[key] = Hash.new}
                phrases = {}
                
                #graph = sentence.css("graph")
                #tpart = graph.css("terminals")
                #STDERR.puts tpart
                terminals = sentence.css("t").to_a
                

                mapping = {}
                terminals.each.with_index do |terminal,index|
                    term_id = index + 1
                    mapping[terminal["id"]] = term_id
                    words[term_id]["word"] = terminal["word"]
                    words[term_id]["pos"] = terminal["pos"]
                    words[term_id]["msd"] = terminal["msd"]
                    words[term_id]["msd2"] = terminal["msd2"]
                    words[term_id]["lemma"] = terminal["lemma"]
                    words[term_id]["read_as"] = terminal["read_as"]
                    words[term_id]["connected"] = terminal["connected"]
                end
                term_ids = words.keys
                #term_ids2, mapping = alltermids_to_integer(term_ids)
                #term_ids = term_ids2.clone

    		    
                nonterminals = sentence.css("nt").to_a
                nonterminals.each do |nonterminal|
                    nonterm_id = nonterminal["id"]
                    cat = nonterminal["cat"]
                    phrases[nonterm_id] = cat
                    edges = nonterminal.css("edge").to_a
                    secedges = nonterminal.css("secedge").to_a
                    #STDERR.puts nonterm_id
                    edges.each do |edge|
                        label = edge["label"]
                        idref = edge["idref"]
                        primary_tree[nonterm_id] << one_termid_to_integer(idref, mapping)
                        primary_labels[nonterm_id] << label
                    end
                    secedges.each do |secedge|
                        seclabel = secedge["label"]
                        secidref = secedge["idref"]
                        secondary_tree[nonterm_id] << secidref
                        secondary_labels[nonterm_id] << seclabel
                    end
                    
                end
                #STDERR.puts "*** #{primary_tree["Romn_Lundqvist-Ingentobak.20.5"]} ***"
                #abort
                @underoldroot = {}
                @reversed_tree = {}
                @reversed_labels = {}
                @reversed_labels2 = {}
                @reversed_secondary_tree = Hash.new{|hash, key| hash[key] = Array.new}
                @reversed_secondary_labels = Hash.new{|hash, key| hash[key] = Array.new}
                
                @newroot = nil
                @under0 = []
                @primary_tree = primary_tree.clone
                @primary_labels = primary_labels.clone
                @head_by_nt = {}
                @root_by_nt = {}
                @mwes_replaced = {}
                #@primary_tree.each_pair do |key,value|
                #    STDERR.puts "#{key},#{value},#{@primary_labels[key]}"
                #    
                #end
                #STDERR.puts ""
                if verbose then STDERR.puts "Dealing with MWEs" end
                deal_with_mwes(primary_tree, "#{sent_id}.0", phrases, term_ids, words, verbose, sent_id)
                #@primary_tree.each_pair do |key,value|
                #    STDERR.puts "#{key},#{value},#{@primary_labels[key]}"
                #    
                #end
                #STDERR.puts ""
                #STDERR.puts @reversed_tree
                #STDERR.puts ""
                #STDERR.puts @reversed_labels
                #STDERR.puts ""
                primary_tree = @primary_tree.clone
                primary_labels = @primary_labels.clone
                #abort
                if verbose then STDERR.puts "*****" end
                if verbose then STDERR.puts "Processing the primary tree" end
                if verbose then STDERR.puts "*****" end
                #@rootlist = []
                @nonterminallinkontop = false
                root = process_primary_tree(primary_tree, primary_labels, "#{sent_id}.0", term_ids, phrases, 0, sent_id,"",verbose, words)

                ###extracted from the process_primary_tree method, since this does not have to be done for every node. The variable root is now the output of the method
                mainroot = 0
                mainroot2 = 0
                
                if @under0.length > 1
                    #if !@sentids_several_nonterminals_on_top.include?(sent_id)
                        #STDOUT.puts sent_id
                    #end
                    #TODO: what are those cases when this occurs, but it's not "several non-terminal on top"?
                    undercounter += 1
                    foundnewmainroot = false
                    #choosing the leftmost node
                    @under0_copy = @under0.clone.sort
                
                          
                    @under0_copy.each do |node|
                        if !@reversed_labels2[node].include?("PH")
                            mainroot = node.clone
                            foundnewmainroot = true
                            break
                        end
                    end
                    if !foundnewmainroot
                        mainroot = @under0_copy[0].clone
                        #@STDOUT.puts "#{sent_id} #{mainroot}"
                    end
	            
                    #choosing the first node (deprecated, here for comparison)
                    foundnewmainroot2 = false
                    @under0.each do |node|
                        if !@reversed_labels2[node].include?("PH")
                            mainroot2 = node.clone
                            foundnewmainroot2 = true
                            break
                        end
                    end
                    if !foundnewmainroot2
                        mainroot2 = @under0[0].clone                
                    end
                    #if mainroot != mainroot2
                        #STDOUT.puts "#{sent_id} #{mainroot} #{mainroot2}"
                    #end
	            
	            
                    @under0.each do |node|
                        if node != mainroot
                            @reversed_tree[node] = mainroot
                        end
                    end
                else
                    mainroot = @newroot.clone
                end
                if @newroot.nil?
                    mainroot = root.clone
                end
                @underoldroot.keys.each do |node|
                    @reversed_tree[node] = mainroot
                end
                ###end of extraction
   

                secondary_tree.each_pair do |nt, towardsarray|
                    seclabelarray = secondary_labels[nt]
    		    
                    towardsarray.each.with_index do |towards, towardsindex|
                        seclabel = seclabelarray[towardsindex]
                        @reversed_secondary_labels[towards] << seclabel
                        if !@head_by_nt[nt].nil?
                            towardshead = @head_by_nt[nt].clone
                        else
                            towardshead = @mwes_replaced[nt]
                        end
    		    
                        if term_ids.include?(towards)
                            @reversed_secondary_tree[towards] << towardshead
                        else
                            @reversed_secondary_tree[@head_by_nt[towards]] << towardshead
                        end
    		    
                    end
                    
                end
    		    
    		    
                #outputfile.puts "# corpus = #{filename}"
                #outputfile.puts "# subcorpus = #{subcorpus_id}"
                if sentnumber == 0
                    outputfile.puts "# newdoc id = #{subcorpus_id}"
                end
                
                outputfile.puts "# sent_id = #{sent_id}"
                
    
                
                text = ""
                term_ids.sort.each do |term_id|
                    info = words[term_id]
                    text << info["word"]
                    if info["connected"] != "rear" and info["connected"] != "both"
                        text << " "
                    end
                end
                if text[-1] == " "
                    text = text[0..-2]
                end
                outputfile.puts "# text = #{text}"
    
                @reversed_tree_newids = {}
                term_ids.sort.each do |term_id|
                    #STDERR.puts term_id
                    info = words[term_id]
                    head = nodeid_to_integer(sent_id,@reversed_tree[term_id])
                    deprel = @reversed_labels[term_id]
                    if deprel == "--" and info["pos"][0..1] != "SY" and head != 0 and !@sentids_several_nonterminals_on_top.include?(sent_id)
                        STDOUT.puts "#{sent_id}\t#{term_id}"
                    end

                    if @reversed_secondary_tree[term_id].length != 0
                        secdep = "#{head}:#{deprel}"
                        seclabel = ""
                        @reversed_secondary_tree[term_id].each.with_index do |from,fromindex|
                            seclabel = @reversed_secondary_labels[term_id][fromindex]
                            secdep << "|#{nodeid_to_integer(sent_id,from)}:#{seclabel}"
                        end
                        
                        
                    end
                    misc = []
                    if info["read_as"] != ""
                        misc << "CorrectForm=#{info["read_as"]}"
                    end
                    if info["connected"] == "rear" or info["connected"] == "both"
                        misc << "SpaceAfter=No"
                    end
                    misc = misc.join("|")
                    
                    new_nodeid = nodeid_to_integer(sent_id,term_id)
                    outputfile.puts "#{new_nodeid}\t#{info["word"]}\t#{info["lemma"]}\t#{info["pos"]}\t#{info["msd2"]}\t#{info["msd"]}\t#{head}\t#{deprel}\t#{secdep}\t#{misc}"
                    @reversed_tree_newids[new_nodeid] = head
                end
                #STDERR.puts @reversed_tree
                #STDERR.puts @reversed_labels
                
                #abort
                
                outputfile.puts ""
                #STDERR.puts "#{@reversed_tree_newids}"
                @disconnected_ids = []
                status, nheads, detailed_status = check_reversed_tree(@reversed_tree_newids)
                if status != 0 
                    tree_error_file.puts "#{sent_id}\t#{nheads}\t#{detailed_status}\t#{@disconnected_ids.uniq}"
                end

                n_wrong_trees += status
                n_processed_sents += 1
            end
        end
    
    
    end
end
STDERR.puts "Excluded sentences: #{excluded_sents.keys.length}. Processed sentences: #{n_processed_sents}. Invalid trees: #{n_wrong_trees}"
#STDERR.puts "Sentences where there are only terminals on top, and more than one have other POS than SY: #{@n_only_terminals_on_top}"
STDERR.puts "Sentences where there are several nonterminals on top: #{@nsents_several_nonterminals_on_top}"
#@cat_combinations_on_top.each_pair do |combination,freq| 
#    STDOUT.puts "#{combination}\t#{freq}"
#end
#STDERR.puts undercounter