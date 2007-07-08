module Redwood

class LabelListMode < LineCursorMode
  register_keymap do |k|
    k.add :select_label, "Select label", :enter
    k.add :reload, "Discard label list and reload", 'D'
  end

  bool_reader :done
  attr_reader :value

  def initialize
    @labels = []
    @text = []
    @done = false
    @value = nil
    super
    regen_text
  end

  def lines; @text.length end
  def [] i; @text[i] end

protected

  def reload
    regen_text
    buffer.mark_dirty if buffer
  end
  
  def regen_text
    @text = []
    @labels = LabelManager.listable_label_strings

    counts = @labels.map do |string|
      label = LabelManager.label_for string
      total = Index.num_results_for :label => label
      unread = Index.num_results_for :labels => [label, :unread]
      [label, string, total, unread]
    end      

    width = @labels.max_of { |string| string.length }

    counts.map do |label, string, total, unread|
      if total == 0 && !LabelManager::RESERVED_LABELS.include?(label)
        Redwood::log "no hits for label #{label}, deleting"
        LabelManager.delete t
        next
      end

      @text << [[(unread == 0 ? :labellist_old_color : :labellist_new_color),
          sprintf("%#{width + 1}s %5d %s, %5d unread", string, total, total == 1 ? " message" : "messages", unread)]]
      yield i if block_given?
    end.compact
  end

  def select_label
    @value, string = @labels[curpos]
    @done = true if @value
  end
end

end
