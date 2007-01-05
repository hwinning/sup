module Redwood

class PersonSearchResultsMode < ThreadIndexMode
  def initialize people
    @people = people
    super
  end

  def is_relevant? m; @people.any? { |p| m.from == p }; end

  def load_threads opts={}
    n = opts[:num] || ThreadIndexMode::LOAD_MORE_THREAD_NUM
    load_n_threads_background n, :participants => @people,
                                 :load_killed => true,
                                 :load_spam => false,
                                 :when_done =>(lambda do |num|
      opts[:when_done].call if opts[:when_done]
      if num > 0
        BufferManager.flash "Found #{num} threads"
      else
        BufferManager.flash "No matches"
      end
    end)
  end
end

end
