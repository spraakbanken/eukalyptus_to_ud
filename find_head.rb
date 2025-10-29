def find_head(labels,current_id,next_level,primary_tree,primary_labels,sent_id)
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
            find_head(primary_labels[temphead],temphead,primary_tree[temphead],primary_tree,primary_labels,sent_id)
        end
    end

    return head
end

            head_label_index = labels.index("HD") 
            
            if head_label_index.nil?
                head_label_index = labels.index("PH")
            else
                if verbose then STDERR.puts "Current_id: #{current_id} HD found: #{next_level[head_label_index]}" end
            end

                if verbose then STDERR.puts "Current_id: #{current_id} HD or PH found: #{next_level[head_label_index]}" end
                temphead = next_level[head_label_index].clone
                if term_ids.include?(temphead)
                    head = temphead.clone
                    if verbose then STDERR.puts "Current_id: #{current_id} HD or PH confirmed as terminal: #{next_level[head_label_index]}" end
                else
                    ADD TESTING FOR NT, DO A RECURSION, TEST ON WIDER SAMPLE
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                                     
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "************************" end
                    if verbose then STDERR.puts "Current_id: #{current_id} HD or PH erased: non-terminal" end
                    #head_label_index = nil
                    #head_label_index_nt = head_label_index.clone

                    downnodes = primary_tree[temphead]
                    if verbose then STDERR.puts "Current_id: #{current_id}. Looking at nodes in #{temphead}" end
                    downlabels = primary_labels[temphead]
                    if verbose then STDERR.puts "Current_id: #{current_id}. Looking at labels in #{temphead}" end
                    head_label_index = downlabels.index("HD")
                    #if verbose then STDERR.puts "HD head: #{downnodes[head_label_index]}" end
                    #check if it is an NT


                    if head_label_index.nil?
                        head_label_index = downlabels.index("PH")
                        #if verbose then STDERR.puts "PH index: #{downnodes[head_label_index]}" end
                    #else
                        #STDOUT.puts "#{sent_id}\tSuccesfully found an HD in one step down"
                    end
                    if head_label_index.nil?
                        #STDOUT.puts "#{sent_id}\twent down from #{current_id}\t#{head_label_index_nt} does not contain a head"
                        if verbose then STDERR.puts "#{sent_id}\twent down from #{current_id}\t#{temphead} does not contain a head" end
                    end
                end