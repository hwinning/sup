# encoding: utf-8

module Redwood

  class ContactManager
    include Redwood::Singleton

    def initialize(fn)
      @fn = fn

      ## maintain the mapping between people and aliases. for contacts without
      ## aliases, there will be no @a2p entry, so @p2a.keys should be treated
      ## as the canonical list of contacts.

      @p2a = {} # person to alias
      @a2p = {} # alias to person
      @e2p = {} # email to person

      if File.exist?(fn)
        IO.foreach(fn) do |l|
            l.match(/^([^:]*): ([^:]*): (.*)$/) or l.match(/^([^:]*): (.*)$/) or raise "can't parse #{fn} line #{l.inspect}"
          aalias, addr, default_from = $1, $2, $3
          p = Person.from_address(addr)
          p.default_from = default_from if default_from
          update_alias(p, aalias)
        end
      end
    end

    def contacts; @p2a.keys end
    def contacts_with_aliases; @a2p.values.uniq end

    def update_alias(person, aalias=nil)
      ## Deleting old data if it exists
      old_aalias = @p2a[person]
      if old_aalias
        @a2p.delete old_aalias
        @e2p.delete person.email
      end
      ## Update with new data
      @p2a[person] = aalias
      @e2p[person.email] = person
      unless aalias.nil? || aalias.empty?
        @a2p[aalias] = person
        #@e2p[person.email] = person	# e2p is only initialized if the person has an alias?
      end
    end

    ## this may not actually be called anywhere, since we still keep contacts
    ## around without aliases to override any fullname changes.
    def drop_contact person
      aalias = @p2a[person]
      @p2a.delete person
      @e2p.delete person.email
      @a2p.delete aalias if aalias
    end

    def contact_for aalias; @a2p[aalias] end
    def alias_for person; @p2a[person] end
    def person_for email; @e2p[email] end
    def is_aliased_contact? person; !@p2a[person].nil? end

    def save
      File.open(@fn, "w:UTF-8") do |f|
        @p2a.sort_by { |(p, a)| [p.full_address, a] }.each do |(p, a)|
          #f.puts "#{a || ''}: #{p.full_address}"
          f.puts "#{a || ''}: #{p.full_address}: #{p.default_from}"
        end
      end
    end
  end

end
