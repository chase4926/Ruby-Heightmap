#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)

$VERBOSE = true

$WINDOW_WIDTH = 640
$WINDOW_HEIGHT = 640

require 'rubygems'
require 'gosu'
include Gosu

require_relative '../lib/lib.rb'
require_relative '../lib/lib_misc.rb'
require_relative '../lib/lib_alphabet.rb'
require_relative 'heightmap.rb'


puts "Input the seed you wish to use, or leave empty to use the current time.\n\n"
print '>>'
input = gets().chomp()
seed = ''
if input.length() > 0 then
  input.each_char() do |char|
    seed << char.ord().to_s()
  end
  seed = seed.to_i()
else
  seed = Time.now().to_i()
end
puts "Using seed: #{seed}"

srand(seed)


def draw_square(window, x, y, z, width, height, color = 0xffffffff)
  window.draw_quad(x, y, color, x + width, y, color, x, y + height, color, x + width, y + height, color, z)
end


class GameWindow < Gosu::Window
  def initialize()
    super($WINDOW_WIDTH, $WINDOW_HEIGHT, false)
    self.caption = 'Heightmap Visualizer'
    Alphabet::initialize(self)
    @heightmap = HeightMap.new(40, 40)
    @grid = @heightmap.get_grid()
    @tile_width = $WINDOW_WIDTH.to_f() / @heightmap.width
    @tile_height = $WINDOW_HEIGHT.to_f() / @heightmap.height
    
    # Color
    @contrast = 6
  end # End GameWindow Initialize
  
  def update()
  end # End GameWindow Update
  
  def mouse_x_cell()
    return (mouse_x / @tile_width).floor()
  end
  
  def mouse_y_cell()
    return (mouse_y / @tile_height).floor()
  end
  
  def get_height_color(height)
    value = (@contrast * height) + 127
    if value > 255 then
      value = 255
    elsif value < 0 then
      value = 0
    end
    if height >= 0 then
      return Gosu::Color.new(255, 0, value, 0)
    else
      return Gosu::Color.new(255, 0, 0, value)
    end
  end
  
  def draw()
    @grid.each_with_index() do |row, y|
      row.each_with_index do |height, x|
        draw_square(self, x * @tile_width, y * @tile_height, 1, @tile_width, @tile_height, get_height_color(height))
      end
    end
    Alphabet::draw_text(@heightmap.get(mouse_x_cell(), mouse_y_cell()), mouse_x + 16, mouse_y - 4, 2, 4)
    Alphabet::draw_text("Contrast: #{@contrast}", 16, 16, 2, 4)
  end # End GameWindow Draw
  
  def button_down(id)
    case id
      when Gosu::Button::KbEscape
        # Close window on escape
        close()
      when Gosu::Button::KbSpace
        # Go through generation on grid
        if button_down?(Gosu::Button::KbLeftShift) or button_down?(Gosu::Button::KbRightShift) then
          # Shift is pressed, do 10 generations
          @heightmap.generate(10)
        else
          # Shift is not pressed, do 1 generation
          @heightmap.generate(1)
        end
        @grid = @heightmap.get_grid()
      when Gosu::Button::KbZ
        # Weak static
        @heightmap.static()
        @grid = @heightmap.get_grid()
      when Gosu::Button::KbX
        # Strong static
        @heightmap.static(100)
        @grid = @heightmap.get_grid()
      when Gosu::Button::MsLeft
        # Calculate new height on cell under cursor
        @heightmap.set(mouse_x_cell(), mouse_y_cell(), @heightmap.calculate_new_height(mouse_x_cell(), mouse_y_cell()))
        @grid = @heightmap.get_grid()
      when 26
        # Left square bracket
        # Decrease contrast
        @contrast -= 1
      when 27
        # Right square bracket
        # Increase contrast
        @contrast += 1
      when Gosu::Button::KbF1
        @heightmap.save('heightmap.dat')
      when Gosu::Button::KbF2
        @heightmap.load('heightmap.dat')
        @grid = @heightmap.get_grid()
    end
  end
  
  def needs_cursor?()
    return true
  end
end # End GameWindow class


window = GameWindow.new().show()
