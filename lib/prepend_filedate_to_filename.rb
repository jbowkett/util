require 'find'

class PrependFiledateToFilename
  def format(date)
    date.strftime('%Y%m%d')
  end


  def apply_to_all(start_dir)
    Dir.foreach(start_dir) do |fname|
      input_file = File.new("#{start_dir}/#{fname}")
      next if File.directory?fname
      new_filename = "#{format(File.mtime(input_file))}_#{fname}"

      puts " rename #{fname} => #{new_filename}"

      File.rename(input_file, "#{start_dir}/#{new_filename}")
    end
  end
end

if ARGV.length != 1
  puts 'Usage: PrependFiledateToFilename <start dir>'
  exit -1
end

PrependFiledateToFilename.new.apply_to_all(ARGV[0])
