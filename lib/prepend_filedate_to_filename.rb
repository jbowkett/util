class PrependFiledateToFilename
  def format(date)
    date.strftime('%Y%m%d')
  end


  def apply_to_all(start_dir)
    Dir.glob(start_dir + '/*') do |file|
      date_portion = format(File.mtime(file))

      new_filename = "#{date_portion}_#{File.basename(file)}"

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
