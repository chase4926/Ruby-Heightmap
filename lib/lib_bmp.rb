
# Author: Gregory Brown
# Found on: https://practicingruby.com/articles/shared/oelhlibhtlkx

class BMP
  class Writer
    PIXEL_ARRAY_OFFSET = 54
    BITS_PER_PIXEL     = 24
    DIB_HEADER_SIZE    = 40
    PIXELS_PER_METER   = 2835 # 2835 pixels per meter is basically 72dpi
    
    def initialize(width, height)
      @width, @height = width, height
      @pixels = Array.new(@height) { Array.new(@width) { "000000" } }
    end
    
    def []=(x,y,value)
      @pixels[y][x] = value
    end
    
    def save_as(filename)
      File.open(filename, "wb") do |file|
        write_bmp_file_header(file)
        write_dib_header(file)
        write_pixel_array(file)
      end
    end
    
    def write_bmp_file_header(file)
      file << ["BM", file_size, 0, 0, PIXEL_ARRAY_OFFSET].pack("A2Vv2V")
    end
    
    def file_size
      PIXEL_ARRAY_OFFSET + pixel_array_size 
    end
    
    def pixel_array_size
      ((BITS_PER_PIXEL*@width)/32.0).ceil*4*@height
    end
    
    def write_dib_header(file)
      file << [DIB_HEADER_SIZE, @width, @height, 1, BITS_PER_PIXEL,
      0, pixel_array_size, PIXELS_PER_METER, PIXELS_PER_METER, 
      0, 0].pack("V3v2V6")
    end
    
    def write_pixel_array(file)
      @pixels.reverse_each do |row|
        row.each do |color|
          file << pixel_binstring(color)
        end
        file << row_padding
      end
    end
    
    def pixel_binstring(rgb_string)
      raise ArgumentError unless rgb_string =~ /\A\h{6}\z/
      [rgb_string].pack("H6")
    end
    
    def row_padding
      "\x0" * (@width % 4)
    end
  end
  
  class Reader
    PIXEL_ARRAY_OFFSET = 54
    BITS_PER_PIXEL     = 24
    DIB_HEADER_SIZE    = 40
    
    attr_reader :width, :height
    def initialize(bmp_filename) 
      File.open(bmp_filename, "rb") do |file|
        read_bmp_header(file) # does some validations
        read_dib_header(file) # sets @width, @height
        read_pixels(file)     # populates the @pixels array
      end
    end
    
    def [](x,y)
      @pixels[y][x]
    end
    
    def read_bmp_header(file)
      header = file.read(14)
      magic_number, file_size, reserved1,
      reserved2, array_location = header.unpack("A2Vv2V")
      fail "Not a bitmap file!" unless magic_number == "BM"
      unless file.size == file_size
        fail "Corrupted bitmap: File size is not as expected" 
      end
      unless array_location == PIXEL_ARRAY_OFFSET
        fail "Unsupported bitmap: pixel array does not start where expected"
      end
    end

    def read_dib_header(file)
      header = file.read(40)
      header_size, width, height, planes, bits_per_pixel, 
      compression_method, image_size, hres, 
      vres, n_colors, i_colors = header.unpack("V3v2V6") 
      # Note: the right pattern to use is actually "Vl<2v2V2l<2V2",
      # but that only works on Ruby 1.9.3+
      unless header_size == DIB_HEADER_SIZE
        fail "Corrupted bitmap: DIB header does not match expected size"
      end
      unless planes == 1
        fail "Corrupted bitmap: Expected 1 plane, got #{planes}"
      end
      unless bits_per_pixel == BITS_PER_PIXEL
        fail "#{bits_per_pixel} bits per pixel bitmaps are not supported"
      end
      unless compression_method == 0
        fail "Bitmap compression not supported"
      end
      unless image_size + PIXEL_ARRAY_OFFSET == file.size
        fail "Corrupted bitmap: pixel array size isn't as expected"
      end
      @width, @height = width, height
    end

    def read_pixels(file)
      @pixels = Array.new(@height) { Array.new(@width) }
      (@height-1).downto(0) do |y|
        0.upto(@width - 1) do |x|
          @pixels[y][x] = file.read(3).unpack("H6").first
        end
        advance_to_next_row(file)
      end
    end
    
    def advance_to_next_row(file)
      padding_bytes = @width % 4
      return if padding_bytes == 0
      file.pos += padding_bytes
    end
  end
end

