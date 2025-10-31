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

def find_head(labels,current_id,next_level,primary_tree,primary_labels,sent_id,verbose,term_ids,root,phraselabel)
    @head_label_index = labels.index("HD") 
            
    if @head_label_index.nil?
        @head_label_index = labels.index("PH")
    else
        if verbose then STDERR.puts "Current_id: #{current_id} HD found: #{next_level[@head_label_index]}" end
    end 

    if !@head_label_index.nil?
        if verbose then STDERR.puts "Current_id: #{current_id} HD or PH found: #{next_level[@head_label_index]}" end
        temphead = next_level[@head_label_index].clone
        if term_ids.include?(temphead)
            @head = temphead.clone
            if root == 0 and @newroot.nil? # and cat != "KoP"
                if verbose then STDERR.puts "    Current_id: #{current_id}. New root!" end
                @newroot = @head.clone#.gsub("#{sent_id}.","").to_i
            end
            if root == 0 and !@under0.include?(@head)
                #STDERR.puts "Placing #{@head} under0 in recursion"
                @under0 << @head
            end
            if @reversed_tree[@head].nil?
                @reversed_tree[@head] = root
                @reversed_labels[@head] = phraselabel #"#{labels[nodeindex]}-#{cat}-#{phraselabel}"
                #@reversed_labels2[@head] = "#{labels[nodeindex]}-#{cat}-#{phraselabel}"
                if verbose then STDERR.puts "IN RECURSION #{@head} assigned #{root} as head and #{phraselabel} as label" end
            else
                if verbose then STDERR.puts "IN RECURSION assignment blocked: #{@head} already has #{@reversed_tree[@head]} as head" end
            end
         

            if verbose then STDERR.puts "Current_id: #{current_id} HD or PH confirmed as terminal: #{next_level[@head_label_index]}" end
        else            
            find_head(primary_labels[temphead],temphead,primary_tree[temphead],primary_tree,primary_labels,sent_id,verbose,term_ids,root,phraselabel)
            #add condition for stopping
        end
    else
        if verbose then STDERR.puts "#{current_id}: no HD or PH found, exiting recursion"end
    end

    return
end

def process_primary_tree(primary_tree, primary_labels, current_id, term_ids, phrases, root, sent_id, phraselabel,verbose,words)
    cat = phrases[current_id]
    
    if verbose then STDERR.puts "Current_id: #{current_id}" end
    
    onlyterminalsontop = false    
    discourseterminalontop = {}
    


    until false == true do
        next_level = primary_tree[current_id]
        if verbose then STDERR.puts "Current_id: #{current_id} Next level: #{next_level}" end
        labels = primary_labels[current_id]
        head_label_index = labels.index("HD")  
  
        #assign heads and do some more
        if cat == "Top"
            
            if verbose then STDERR.puts "Current_id: #{current_id} Cat: #{cat}" end

            if next_level.length > 1
                if verbose then STDERR.puts "Current_id: #{current_id} Several nodes under Top. Check if they all are terminal" end
    
                nonterminals = 0
                nonterminal_cats = []
                terminal_nonsy_list = []
                terminalsonly = 1
                
                nonsymbols = 0
                the_nonsymbol = nil
                                
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
                    #STDERR.puts "Several nonterminals!"
                    @nsents_several_nonterminals_on_top += 1
                    @sentids_several_nonterminals_on_top << sent_id
                    combination = nonterminal_cats.sort.uniq.join(", ")
                    #STDERR.puts combination
                    @cat_combinations_on_top[combination]+=1
                    if combination.include?("S") or combination.include?("KoP") or combination.include?("SuP") or combination.include?("VP")
                        @nonterminallinkontop[sent_id] = "parataxis"                  
                    else
                        @nonterminallinkontop[sent_id] = "conj"
                    end                   
                    #STDERR.puts @nonterminallinkontop[sent_id]
                end

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
                        
                        @n_only_terminals_on_top += terminalsonly                       
                    end
                else
                    if nonsymbols > 0
                        terminal_nonsy_list.each do |terminal_nonsy|
                            discourseterminalontop[terminal_nonsy] = true
                        end                      
                    end
                end
            end
        else
            if verbose then STDERR.puts "Current_id: #{current_id} Cat: #{cat}" end

            #collecting info about potentially problematic sentences
            if labels.count("HD") > 1
                @several_hds << "several_heads\t#{sent_id}\t#{current_id}\t#{next_level.select{|n|labels[next_level.index(n)] == "HD"}.join(" ")}"
                
            end
 
            if labels.include?("PH") and labels.include?("HD")
                @phs_hds << "ph_and_hd\t#{sent_id}\t#{current_id}\t#{next_level.select{|n|(labels[next_level.index(n)] == "HD") or (labels[next_level.index(n)]=="PH")}.join(" ")}"
            end

            if labels.count("PH") > 1
                @several_phs << "several_phs\t#{sent_id}\t#{current_id}\t#{next_level.select{|n|labels[next_level.index(n)]=="PH"}.join(" ")}"
            end

            if cat == "KoP"
                if !labels.include?("PH")
                    @nophs_in_kop << "nophs_in_kop\t#{sent_id}\t#{current_id}"
                else
                    if labels.count("PH") > 1
                        @severalphs_in_kop << "severalphs_in_kop\t#{sent_id}\t#{current_id}\t#{next_level.select{|n|labels[next_level.index(n)]=="PH"}.join(" ")}"
                    end
                    next_level.select{|n|labels[next_level.index(n)]=="PH"}.each do |ph|
                        if words[ph]["pos"] != "KO" and words[ph]["pos"] != "SY" and term_ids.include?(ph)
                            @fake_coordinators << "fake_coord\t#{sent_id}\t#{current_id}\t#{ph}\t#{words[ph]["pos"]}"
                        end
                    end
                end
            end
            
            @head = nil
            @head_label_index = nil
            @phraselabel = phraselabel.clone
            STDERR.puts "Running find_head from #{current_id} with #{@phraselabel}"
            find_head(labels,current_id,next_level,primary_tree,primary_labels,sent_id,true,term_ids,root,phraselabel)
            head = @head.clone
            head_label_index = @head_label_index.clone

            if head_label_index.nil?
                if verbose then STDERR.puts "Current_id: #{current_id} No HD or PH found" end
                @headless_counter += 1
                #STDOUT.puts "#{sent_id}\t#{current_id}\t#{cat}\t#{labels.join(" ")}\t#{@secondary_labels[current_id].join(" ")}"
                head_candidates = []
                candidate_index = {}
                #head_old = nil
                #head_label_index_old = nil
                if verbose then STDERR.puts "Current_id: #{current_id} Assigning the leftmost node as a head" end
                
                
                next_level.each.with_index do |node, nodeindex|
                    if term_ids.include?(node)
                        head_candidates << node
                        candidate_index[node] = nodeindex
                    end
                end
                head = head_candidates.min
                head_label_index = candidate_index[head]
                if verbose then STDERR.puts "Current_id: #{current_id} Assigned the leftmost node as a head: #{head}" end
                
                if head_label_index.nil?
                    if verbose then STDERR.puts "Current_id: #{current_id} No first node found. Assigning root #{root} as head" end
                    head = root.clone
                    @root_counter += 1
                elsif
                    @leftmost_counter += 1
                end
            end
        end
        
        @head_by_nt[current_id] = head.clone
        if verbose then STDERR.puts "  Current_id: #{current_id} Root: #{root}" end
        if verbose then STDERR.puts "  Current_id: #{current_id} Head: #{head}" end
        
        next_level.each.with_index do |node,nodeindex|
            if verbose then STDERR.puts "  Current_id: #{current_id}. Terminal run. Node: #{node}" end
            if term_ids.include?(node)
                if verbose then STDERR.puts "    Current_id: #{current_id}. Node: #{node}. Terminal node" end
                @phraselabels[node] = phrases[current_id].clone
                if cat == "Top" and onlyterminalsontop == false #and head == root #head.nil?#root == 0
                    if verbose then STDERR.puts "    Current_id: #{current_id}. Terminal under 0" end
                    #@reversed_tree[node] = root
                    if discourseterminalontop[node] == true
                        @reversed_labels[node] = "discourse"
                    else
                        @reversed_labels[node] = labels[nodeindex]
                    end
                    @underoldroot[node] = true
                else
                    
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
 
                        
                        if root == 0 and !@under0.include?(node)
                            #STDERR.puts "Placing #{node} under0"
                            @under0 << node
                        end
                        #root = node.gsub("#{sent_id}.","").to_i

                        if head != root
                            @reversed_tree[node] = root
                            @reversed_labels[node] = phraselabel #"#{labels[nodeindex]}-#{cat}-#{phraselabel}"
                            @reversed_labels2[node] = "#{labels[nodeindex]}-#{cat}-#{phraselabel}"
                        else 
                            if verbose then STDERR.puts "Root assignment blocked: head = root! #{head}" end
                        end
                    else
                        if verbose then STDERR.puts "    Current_id: #{current_id}. Not a head" end
                        if verbose then STDERR.puts "    Current_id: #{current_id}. Ends up under ('head') #{head}" end
                        @reversed_tree[node] = head #next_level[head_label_index]
                        @reversed_labels[node] = labels[nodeindex]
                    end
                    if verbose then STDERR.puts "********** Tree: #{@reversed_tree} Labels: #{@reversed_labels}" end
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
@nonterminallinkontop = {}
@cat_combinations_on_top = Hash.new(0)
@n_only_terminals_on_top = 0
n_wrong_trees = 0
@headless_counter = 0
@leftmost_counter = 0
@root_counter = 0

@several_hds = []
@phs_hds = []
@several_phs = []
@nophs_in_kop = []
@severalphs_in_kop = []
@fake_coordinators = []


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
                @phraselabels = {}
                @reversed_secondary_tree = Hash.new{|hash, key| hash[key] = Array.new}
                @reversed_secondary_labels = Hash.new{|hash, key| hash[key] = Array.new}
                
                @newroot = nil
                @under0 = []
                @primary_tree = primary_tree.clone
                @primary_labels = primary_labels.clone
                @secondary_tree = secondary_tree.clone
                @secondary_labels = secondary_labels.clone
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
                
                root = process_primary_tree(primary_tree, primary_labels, "#{sent_id}.0", term_ids, phrases, 0, sent_id,"",verbose, words)
                #STDERR.puts "root = #{root}"
                #STDERR.puts "newroot = #{@newroot}"
                ###extracted from the process_primary_tree method, since this does not have to be done for every node. The variable root is now the output of the method
                mainroot = 0
                mainroot2 = 0
                
                if @under0.length > 1
                    if verbose then STDERR.puts "Under0: #{@under0.join(" ")}" end
                    #if !@sentids_several_nonterminals_on_top.include?(sent_id)
                        #STDOUT.puts sent_id
                    #end
                    #TODO: what are those cases when this occurs, but it's not "several non-terminal on top"?
                    undercounter += 1
                    foundnewmainroot = false
                    #choosing the leftmost node
                    @under0_copy = @under0.clone.sort
                    #STDERR.puts @under0_copy.join(" ")
                
                          
                    @under0_copy.each do |node|
                        if !@reversed_labels2[node].include?("PH")
                            mainroot = node.clone
                            foundnewmainroot = true
                            break
                        end
                    end
                    #STDERR.puts mainroot
 
                    if !foundnewmainroot
                        mainroot = @under0_copy[0].clone
                        #@STDOUT.puts "#{sent_id} #{mainroot}"
                    end
                    #STDERR.puts mainroot
	            
                    @under0.each do |node|
                        #STDERR.puts "Going through under0: #{node}, #{@reversed_tree[node]}, #{@reversed_labels[node]}"
                        if node != mainroot
                            @reversed_tree[node] = mainroot
                            if @reversed_labels[node] == "--" and @nonterminallinkontop[sent_id]
                                @reversed_labels[node] = @nonterminallinkontop[sent_id]
                            end
                        end
                    end
                else
                    mainroot = @newroot.clone
                end
                if @newroot.nil?
                    mainroot = root.clone
                end
                #TODO: coord on top labels here, too?
                @underoldroot.keys.each do |node|
                    @reversed_tree[node] = mainroot
                end
                if verbose then STDERR.puts "*** Tree after reassigning from old root: #{@reversed_tree}" end
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
                rootnode = nil
                @reversed_tree.each_pair do |node,head|
                    if head == 0 
                        rootnode = node.clone
                        break
                    end
                end

                term_ids.sort.each do |term_id|
                    #STDERR.puts term_id
                    info = words[term_id]
                    
                    #head = nodeid_to_integer(sent_id,@reversed_tree[term_id])
                    head = @reversed_tree[term_id]


                    deprel = @reversed_labels[term_id]

                    if head.nil?
                        head = rootnode
                        if info["pos"] == "SY"
                            deprel = "punct"
                        else
                            deprel = "dep"
                        end
                    end


                    #if deprel == "--" and info["pos"][0..1] != "SY" and head != 0 #and !@sentids_several_nonterminals_on_top.include?(sent_id)
                    #    STDOUT.puts "#{sent_id}\t#{term_id}"
                    #end

                    if @reversed_secondary_tree[term_id].length != 0
                        secdep = "#{head}:#{deprel}"
                        seclabel = ""
                        @reversed_secondary_tree[term_id].each.with_index do |from,fromindex|
                            seclabel = @reversed_secondary_labels[term_id][fromindex]
                            #secdep << "|#{nodeid_to_integer(sent_id,from)}:#{seclabel}"
                            secdep << "|#{from}:#{seclabel}"
                        end
                        
                        
                    end
                    if @phraselabels[term_id].to_s == "" 
                        if deprel == "ME"
                            @phraselabels[term_id] = @phraselabels[head]
                            if @phraselabels[head].to_s == ""
                                #STDOUT.puts "#{sent_id}\t#{head}\tME head!"
                            end
                        else
                            #STDOUT.puts "#{sent_id}\t#{term_id}"
                        end
                    end

                    misc = ["PhraseLabel=#{@phraselabels[term_id]}"]
                    if info["read_as"] != ""
                        misc << "CorrectForm=#{info["read_as"]}"
                    end
                    if info["connected"] == "rear" or info["connected"] == "both"
                        misc << "SpaceAfter=No"
                    end
                    

                    misc = misc.sort.join("|")
                    
                    #new_nodeid = nodeid_to_integer(sent_id,term_id)
                    new_nodeid = term_id.clone

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
STDERR.puts @headless_counter
STDERR.puts @leftmost_counter
STDERR.puts @root_counter

#@severalphs_in_kop,

#[@phs_hds, @several_phs, @nophs_in_kop,  @fake_coordinators].each do |hdarray|
#    STDOUT.puts hdarray
#end

#@cat_combinations_on_top.each_pair do |combination,freq| 
#    STDOUT.puts "#{combination}\t#{freq}"
#end
#STDERR.puts undercounter