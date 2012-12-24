#!/usr/bin/env ruby


class HeightMap
  attr_reader :width, :height
  def initialize(width, height)
    @grid = Array.new(height){Array.new(width){0}}
    @width = width
    @height = height
  end
  
  def get_grid()
    return Marshal::load(Marshal::dump(@grid))
  end
  
  def set_grid(value)
    # Sets all the cells in the grid to value
    @height.times() do |y|
      @width.times() do |x|
        set(x, y, value)
      end
    end
  end
  
  def get(x, y)
    if x < 0 or y < 0 or x > @width - 1 or y > @height - 1 then
      return 0
    else
      return @grid[y][x]
    end
  end
  
  def set(x, y, value)
    @grid[y][x] = value
  end
  
  def find_min()
    min = get(0, 0)
    value = min
    @height.times() do |y|
      @width.times() do |x|
        value = get(x, y)
        min = value if value < min
      end
    end
    return min
  end
  
  def find_max()
    max = get(0, 0)
    value = max
    @height.times() do |y|
      @width.times() do |x|
        value = get(x, y)
        max = value if value > max
      end
    end
    return max
  end
  
  def get_score(x, y)
    score = 0
    (-1..1).each() do |c|
      (-1..1).each() do |v|
        if c != 0 or v != 0 then
          score += get(x + c, y + v)
        end
      end
    end
    return score
  end
  
  def get_average_difference(x, y, max=6)
    # Averages the height of the surrounding cells- max of 6 both ways
    average_diff = (get_score(x, y) / 8.0).round() - get(x, y)
    if average_diff.abs() > max then
      if average_diff > 0 then
        return max
      else
        return -max
      end
    else
      return average_diff
    end
  end
  
  def calculate_new_height(x, y)
    # Returns the new height that a cell should be assigned
    average_difference = get_average_difference(x, y)
    possibility_array = [-1, 0, 1]
    average_difference.abs().times() do
      possibility_array << average_difference / average_difference.abs()
    end
    return possibility_array.shuffle().pop() + get(x, y)
  end
  
  def calculate_new_height_grid()
    # Randomly calculates each cell's height in the grid
    array = []
    @height.times() do |y|
      @width.times() do |x|
        array << [x, y]
      end
    end
    array.shuffle!()
    until array.empty?() do
      x, y = array.pop()
      set(x, y, calculate_new_height(x, y))
    end
  end
  
  def generate(generations)
    # Generates a heightmap with a given amount of generations
    if generations.to_i() >= 1 then
      generations.to_i().times() do
        calculate_new_height_grid()
      end
    end
  end
  
  def static(generations=20)
    # Generates random static on the grid
    if generations.to_i() >= 1 then
      set_grid(0)
      generations.to_i().times() do
        @height.times() do |y|
          @width.times() do |x|
            set(x, y, get(x, y) + [-1, 0, 1].shuffle().pop())
          end
        end
      end
    end
  end
  
  def average_grid_height()
    # Finds the average height of the cells, then subtracts the average from the cells
    sum = 0
    @height.times() do |y|
      @width.times() do |x|
        sum += get(x, y)
      end
    end
    average = (sum.to_f() / (@height * @width)).round()
    @height.times() do |y|
      @width.times() do |x|
        set(x, y, get(x, y) - average)
      end
    end
  end
end

