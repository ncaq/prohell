# coding: utf-8
# frozen_string_literal: true

require 'pp'
require 'readline'
require 'strscan'

class Prohell
  def initialize(str = nil)
    @rule = Hash.new { |hash, key| hash[key] = [] }
    @s = StringScanner.new(IO.readlines('prelude.phl').join)
    load
    if str
      @s = StringScanner.new(str)
      load
    end
  end

  def load
    until @s.eos?
      t = statement
      @rule[t[0]] << {arg: t[1], body: t[2]}
    end
  end

  def statement
    while token("\n")
    end
    h = head
    if token('=')
      b = [head]
      while token(',')
        b << head
      end
    end
    while token("\n")
    end
    [h[0], *h[1..-1], b]
  end

  def head
    n = name
    arg = []
    while a = term
      arg << a
    end
    [n, arg]
  end

  def name
    token(/[\p{L}\p{N}]+/)
  end

  def term
    case
    when t = token(/\p{Digit}+/)
      [:const, Integer(t)]
    when t = token(/"[^"]+"/)
      [:const, t[1..t.size-2]]
    when token('\+')
      [:in, name]
    when token('-')
      [:out, name]
    when token('\?')
      [:any, name]
    when token('\@')
      [:var, name]
    when t = name
      [:bind, t]
    else
      nil
    end
  end

  def token(a)
    @s.scan(/\p{Blank}*#{a}/)&.lstrip
  end

  def repl
    while line = Readline.readline('?- ', true)
      u = question(line)
      pp u
      puts !u.empty?
    end
  end

  def question(line)
    @s = StringScanner.new(line)
    h = head
    v = select_var(h)
    unify(h).collect {|i|
      if i.kind_of?(Hash)
        i.select { |k| v.include?(k) }
      else
        nil
      end
    }.compact
  end

  def unify(goal)
    match(goal).collect { |m|
      v = m[:var]
      m[:body]&.each { |g|
        g = set(g, v)
        r = unify(g).first
        free = select_var(g)
        if r&.kind_of?(Hash)
          v.merge!(r.select { |i| free.include?(i) })
        elsif r == true
          v = {}
          break
        else
          v = false
          break
        end
      }
      v
    }
  end

  def set(g, var)
    [g[0], g[1].collect { |i|
       if i[0] == :bind
         var[i[1]] || i
       else
         i
       end
     }]
  end

  def select_var(g)
    g[1].select { |i| i[0] == :var }.collect { |i| i[1] }
  end

  # 変形される項 = const | in | out | any
  # 質問 = const | var
  def match(goal)
    rule = @rule[goal[0]]
    if rule.empty?
      if goal[0] == "builtin"
        body = goal[1]
        [{ var:
             case body[0]
             when [:const, "add++-"]
               {body[3][1] => [:const, body[1][1] + body[2][1]]}
             when [:const, "sub++-"]
               {body[3][1] => [:const, body[1][1] - body[2][1]]}
             when [:const, "mul++-"]
               {body[3][1] => [:const, body[1][1] * body[2][1]]}
             when [:const, "less++"]
               body[1][1] < body[2][1]
             else
               fail "組み込み述語 #{body} は存在しません"
             end
         }]
      else
        fail "述語 #{goal} が存在しません"
      end
    else
      rule.collect { |t|
        bm = t[:arg].zip(goal[1]).collect { |a, q|
          case a[0]
          when :const
            case q[0]
            when :const
              a[1] == q[1]
            when :var
              [q[1], [:const, a[1]]]
            end
          when :in
            case q[0]
            when :const
              [a[1], [:const, q[1]]]
            when :var
              nil
            end
          when :out
            case q[0]
            when :const
              nil
            when :var
              [a[1], [:var, q[1]]]
            end
          when :any
            case q[0]
            when :const
              [a[1], [:const, q[1]]]
            when :var
              [a[1], [:var, q[1]]]
            end
          end
        }
        if bm.all?
          {var: Hash[bm.select { |a| a.is_a?(Array) }], body: t[:body] }
        else
          nil
        end
      }.compact
    end
  end
end

def main
  Prohell.new.repl
end

main
