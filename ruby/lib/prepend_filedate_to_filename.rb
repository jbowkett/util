require 'pathname'
class PrependFiledateToFilename
  def format(date)
    date.strftime('%Y%m%d')
  end


  def apply_to_all(start_dir)
    Pathname.glob(start_dir + '/*') do |file|
      date_portion = format(file.mtime)

      new_filename = "#{date_portion}_#{file.basename}"

      puts " rename #{file} => #{new_filename}"

      File.rename(file, "#{start_dir}/#{new_filename}")
    end
  end
end

if ARGV.length != 1
  puts 'Usage: PrependFiledateToFilename <start dir>'
  exit -1
end

PrependFiledateToFilename.new.apply_to_all(ARGV[0])
