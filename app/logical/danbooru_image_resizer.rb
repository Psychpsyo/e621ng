module DanbooruImageResizer
  def resize(file, width, height, resize_quality = 90)
    image = Magick::Image.read(file.path).first
    geometry = "#{width}x>"

    if width == Danbooru.config.small_image_width
      # wider than it is tall
      geometry = "#{Danbooru.config.small_image_width}x#{Danbooru.config.small_image_width}>"
    end

    image.change_geometry(geometry) do |new_width, new_height, img|
      img.resize!(new_width, new_height)
      width = new_width
      height = new_height
    end

    image = flatten(image, width, height)
    image.strip!

    output_file = Tempfile.new(binmode: true)
    image.write("jpeg:" + output_file.path) do
      self.quality = resize_quality
      # setting PlaneInterlace enables progressive encoding for JPEGs
      self.interlace = Magick::PlaneInterlace
    end

    image.destroy!
    output_file
  end

  def flatten(image, width, height)
    if image.alpha?
      # since jpeg can't represent transparency, we need to create an image list,
      # put a white image on the bottom, then flatten it.

      list = Magick::ImageList.new
      list.new_image(width, height) do
        self.background_color = "#FFFFFF"
      end
      list << image
      flattened_image = list.flatten_images
      list.each do |image|
        image.destroy!
      end
      return flattened_image
    else
      return image
    end
  end

  module_function :resize, :flatten
end
