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