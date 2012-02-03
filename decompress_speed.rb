#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# usage:
#  ruby decompress_speed.rb <filename>
#  ruby decompress_speed.rb <option> <dirname>
#  specify type of the files inside (--gz, --bz2) when a directory on argument.
#

require "fileutils"
require "twitter"

Twitter.configure do |config|
	config.consumer_key = "hU0cWBcrnmfMwZPVOrw"
	config.consumer_secret = "PBuZx7CIFzcO84vY3of1ZuCHxsl71pgQ6bTagCs5rM"
	config.oauth_token = "12751992-JG4zLcNXstbErY6c5W9ChVouQtEM8emi9phH4G0yI"
	config.oauth_token_secret = "kVvykW8HSWdDAPlUlevgiaQbECkY9PmJYxDnkZHt54"
end

def decomp_sra(litesra)
	FileUtils.cp "#{litesra}" "#{litesra}_rep"
	time = `(/usr/bin/time -f "%e" ~/local/bin/sratoolkit/fastq-dump --split-3 #{litesra} > /dev/null) 2>&1`.to_f
	FileUtils.mv "#{litesra}_rep" "#{litesra}"
	time
end

def decomp_gz(gz)
	FileUtils.rm_f "#{gz}_out" if File.exist?("#{gz}_out")
	`(/usr/bin/time -f "%e" gunzip -c #{gz} > #{gz}_out) 2>&1`.to_f
end

def decomp_gzall(dir)
	FileUtils.rm_f "#{dir}_out" if File.exist?("#{dir}_out")
	`(/usr/bin/time -f "%e" gunzip -r -c #{dir} > #{dir}_out) 2>&1`.to_f
end

def decomp_bz2(bz2)
	`(/usr/bin/time -f "%e" bunzip2 -k #{bz2} > /dev/null) 2>&1`.to_i
end

def decomp_bz2all(dir)
	sam = Dir.entries(dir).select{|fname| fname =~ /.bz2$/ }.map do |fname|
		`(/usr/bin/time -f "%e" bunzip2 -k #{dir}/#{fname} > /dev/null) 2>&1`.to_f
	end
	sam.reduce(:+)
end

def report(input, avgtime, avgspeed)
	puts "#{input}: avgtime => #{avgtime}, avgspeed => #{avgspeed}"
	tw = Twitter::Client.new
	tw.update("@inut processo per #{input} ha finito")
end


if __FILE__ == $0
	if ARGV.length == 1
		input = ARGV.first

		if input =~ /sra$/
			avgtime = 3.times.map{ decomp_sra(input) }.reduce(:+) / 3
			avgspeed = avgtime / File.size(input)
			report(input, avgtime, avgspeed)
	
		elsif input =~ /gz$/
			avgtime = 3.times.map{ decomp_gz(input) }.reduce(:+) / 3
			avgspeed = avgtime / File.size(input)
			report(input, avgtime, avgspeed)

		elsif input =~ /bz2$/
			avgtime = 3.times.map{ decomp_bz2(input) }.reduce(:+) / 3
			avgspeed = avgtime / File.size(input)
			report(input, avgtime, avgspeed)
	
	else
		option = ARGV.first
		input = ARGV[1]
		
		if option == "--gz"
			avgtime = 3.times.map{ decomp_gzall(input) }.reduce(:+) / 3
			avgspeed = avgtime / Dir.glob(*.gz).map{|f| File.size(f) }.reduce(:+)
			report(input, avgtime, avgspeed)
			
		elsif option == "--bz2"
			avgtime = 3.times.map{ decomp_bz2all(input) }.reduce(:+) / 3
			avgspeed = avgtime / Dir.glob(*.bz2).map{|f| File.size(f) }.reduce(:+)
			report(input, avgtime, avgspeed)
		end
	end
end
