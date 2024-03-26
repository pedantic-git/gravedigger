#!/usr/bin/env ruby

require 'matrix'

puts "GRAVE DIGGER"

class Graveyard
  class FinishError < StandardError; end

  attr_accessor :map, :me, :skeletons, :turns, :digs, :move

  MOVES = {
    n: Vector[-1,0],
    e: Vector[0,1],
    s: Vector[1,0],
    w: Vector[0,-1]
  }

  def initialize
    @go = true
    @map = Matrix.build(10,20) {|r,c| r == 0 || r == 9 || c == 0 || c == 19 ? ':' : ' '}
    map[8,19] = ' '
    20.times { map[rand(1..8), rand(2..17)] = '+' }
    @me = Vector[1,1]
    @skeletons = [Vector[3,18], Vector[2,18], Vector[1,18]]
    draw_skeletons
    @turns = 0
    @digs = 5
  end

  def draw_skeletons
    skeletons.each {|s| map[*s] = 'X'}
  end

  def run!
    system 'stty', '-icanon', '-echo'
    loop do
      self.turns += 1
      finish :midnight if turns > 60
      display
      get_move
      handle_move
      check_win
      move_skeletons
    end
  rescue FinishError
    # Game ends
  ensure
    system 'stty', 'icanon', 'echo'
  end

  def display
    map[*me] = '*'
    puts
    puts map.to_a.map(&:join).join("\n")
  end

  def finish(code)
    case code
    when :skeleton
      puts "URK! YOU'VE BEEN SCARED TO DEATH BY A SKELETON"
    when :midnight
      puts "THE CLOCK'S STRUCK MIDNIGHT"
      puts "AGHHHHH!!!!"
    when :hole
      puts "YOU'VE FALLEN INTO ONE OF YOUR OWN HOLES"
    when :win
      puts "YOU'RE FREE**"
      puts "YOUR PERFORMANCE RATING IS #{performance}%"
    end
    raise FinishError
  end

  def get_move
    self.move = nil
    until move
      puts "ENTER MOVE #{turns} (YOU CAN GO N,S,E OR W)"
      self.move = MOVES.fetch($stdin.getc.downcase.to_sym, nil)
    end
  end

  def handle_move
    new_me = me + move
    case map[*new_me]
    when ' '
      get_dig
      map[*me] = ' ' if map[*me] == '*'
      self.me = new_me
    when ':', '+'
      puts "THAT WAY'S BLOCKED"
    when 'O'
      finish :hole
    when 'X'
      finish :skeleton
    end
  end

  def get_dig
    if digs > 0
      puts "WOULD YOU LIKE TO DIG A HOLE? (Y OR N)"
      if $stdin.getc.downcase == 'y'
        map[*me] = 'O'
        self.digs -= 1
      end
    end
  end

  def check_win
    if me[1] == 19
      finish :win
    end
  end

  def move_skeletons
    skeletons.each.with_index do |skel, i|
      MOVES.each_value {|v| finish(:skeleton) if skel + v == me }
      if move == MOVES[:s] && map[*skel + MOVES[:s]] == ' '
        skeletons[i] = skel + MOVES[:s]
        map[*skel] = ' '
      elsif move == MOVES[:n] && map[*skel + MOVES[:n]] == ' '
        skeletons[i] = skel + MOVES[:n]
        map[*skel] = ' '
      elsif move == MOVES[:e] && me[1] > skel[1] && map[*skel + MOVES[:e]] == ' '
        skeletons[i] = skel + MOVES[:e]
        map[*skel] = ' '
      elsif move == MOVES[:e] && map[*skel + MOVES[:w]] == ' '
        skeletons[i] = skel + MOVES[:w]
        map[*skel] = ' '
      end
    end
    draw_skeletons
  end
  
  def performance
    ((60-turns).to_f/60*(96+digs)).to_i
  end
end

g = Graveyard.new
g.run!