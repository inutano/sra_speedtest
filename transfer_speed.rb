#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# required: ./SRA_Accessions.tab (download at ftp.ncbi.nlm.nih.gov/sra/report/Metadata/SRA_Accessions.tab)

require "fileutils"

class SRATransfer
	def initialize(runid, accessions)
		@runid = runid
		@run_db = runid.slice(0,3)
		@run_head = runid.slice(0,6)
		converter = File.open(accessions).readlines.select{|l| l =~ /^#{@runid}/ }.first.split("\t")
		@expid = converter[10]
		@exp_db = @expid.slice(0,3)
		@exp_head = @expid.slice(0,6)
		@accid = converter[1]
		@acc_head = @accid.slice(0,6)
		@tim = '/usr/bin/time -f "%e"'
		@ascp = "~/.aspera/connect/bin/ascp -q -k1 -QT"
		@putty = "~/.aspera/connect/etc/asperaweb_id_dsa.putty"
	end
	attr_reader :runid
	attr_reader :expid
	attr_reader :accid
	
	def ncbi_ls_ftp(pnum)
		FileUtils.rm_rf "./ncbi/#{@runid}_nlf"
		loc = "ftp.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/litesra/#{@run_db}/#{@run_head}"
		puts loc
		`(#{@tim} lftp -c "open #{loc} && mirror --parallel=#{pnum} #{@runid} ./ncbi/#{@runid}_nlf") 2>&1`.to_f
	end
	def ncbi_ls_aspera
		FileUtils.rm_rf "./ncbi/#{@runid}_nla"
		loc = "anonftp@ftp-trace.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/litesra/#{@run_db}/#{@run_head}/#{@runid}"
		puts loc
		`(#{@tim} #{@ascp} -i #{@putty} #{loc} ./ncbi/#{@runid}_nla) 2>&1`.to_f
	end
	def ebi_ls_ftp(pnum)
		FileUtils.rm_rf "./ebi/#{@runid}_elf"
		loc = "ftp.sra.ebi.ac.uk/vol1/#{@run_db.downcase}/#{@run_head}"
		puts loc
		FileUtils.mkdir "./ebi/#{@runid}_elf"
		`(#{@tim} lftp -c "open #{loc} && pget -n #{pnum} -O ./ebi/#{@runid}_elf #{@runid}") 2>&1`.to_f
	end
	def ebi_ls_aspera
		FileUtils.rm_rf "./ebi/#{@runid}_ela"
		loc = "era-fasp@fasp.sra.ebi.ac.uk:/vol1/#{@run_db.downcase}/#{@run_head}/#{@runid}"
		puts loc
		`(#{@tim} #{@ascp} -i #{@putty} #{loc} ./ebi/#{@runid}_ela) 2>&1`.to_f
	end
	def ebi_fq_ftp(pnum)
		FileUtils.rm_rf "./ebi/#{@runid}_eff"
		loc = "ftp.sra.ebi.ac.uk/vol1/fastq/#{@run_head}"
		puts loc
		`(#{@tim} lftp -c "open #{loc} && mirror --parallel=#{pnum} #{@runid} ./ebi/#{@runid}_eff") 2>&1`.to_f
	end
	def ebi_fq_aspera
		FileUtils.rm_rf "./ebi/#{@runid}_efa"
		loc = "era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/#{@run_head}/#{@runid}"
		puts loc
		`(#{@tim} #{@ascp} -i #{@putty} #{loc} ./ebi/#{@runid}_efa) 2>&1`.to_f
	end
	def ddbj_ls_ftp(pnum)
		FileUtils.rm_rf "./ddbj/#{@runid}_dlf"
		loc = "ftp.ddbj.nig.ac.jp/ddbj_database/dra/sralite/ByExp/litesra/#{@exp_db}/#{@exp_head}/#{@expid}"
		puts loc
		`(#{@tim} lftp -c "open #{loc} && mirror --parallel=#{pnum} #{@runid} ./ddbj/#{@runid}_dlf") 2>&1`.to_f
	end
	def ddbj_fq_ftp(pnum)
		FileUtils.rm_rf "./ddbj/#{@runid}_dff"
		loc = "ftp.ddbj.nig.ac.jp/ddbj_database/dra/fastq/#{@acc_head}/#{@accid}"
		puts loc
		FileUtils.mkdir "./ddbj/#{@runid}_dff"
		`(#{@tim} lftp -c "open #{loc} && mirror --parallel=#{pnum} #{@expid} ./ddbj/#{@runid}_dff") 2>&1`.to_f
	end
	def report(avgtime, size, pnum = 0)
		if size
			avgspeed = size / avgtime
			puts "total size => #{size}, parallel => #{pnum}, avgtime => #{avgtime}, avgspeed => #{avgspeed}"
		else
			puts "process may be failed - size: nil"
		end
	end
end

if __FILE__ == $0	
	runid = ARGV.first
	accessions = "./SRA_Accessions.tab"
	transfer = SRATransfer.new(runid, accessions)
	
	puts "RunID: #{transfer.runid}, ExperimentID: #{transfer.expid}, AccsessionID: #{transfer.accid}"
	
	puts "litesra from NCBI, lftp"
	[1,2,4,8].each do |pnum|
		avgtime = 3.times.map{ transfer.ncbi_ls_ftp(pnum) }.reduce(:+) / 3
		size = Dir.glob("./ncbi/#{runid}_nlf/*.sra").map{|f| File.size(f) }.reduce(:+)
		transfer.report(avgtime, size, pnum)
	end
	
	puts "litesra from NCBI, aspera connect"
	avgtime = 3.times.map{ transfer.ncbi_ls_aspera }.reduce(:+) / 3
	size = Dir.glob("./ncbi/#{runid}_nla/*.sra").map{|f| File.size(f) }.reduce(:+)
	transfer.report(avgtime, size)
	
	puts "litesra from EBI, lftp"
	[1,2,4,8].each do |pnum|
		avgtime = 3.times.map{ transfer.ebi_ls_ftp(pnum) }.reduce(:+) / 3
		size = Dir.glob("./ebi/#{runid}_elf/*.sra").map{|f| File.size(f)}.reduce(:+)
		transfer.report(avgtime, size, pnum)
	end
	
	puts "litesra from EBI, aspera connect"
	avgtime = 3.times.map{ transfer.ebi_ls_aspera }.reduce(:+) / 3
	size = Dir.glob("./ebi/#{runid}_ela/*.sra").map{|f| File.size(f) }.reduce(:+)
	transfer.report(avgtime, size)
	
	puts "fastq from EBI, lftp"
	[1,2,4,8].each do |pnum|
		avgtime = 3.times.map{ transfer.ebi_fq_ftp(pnum) }.reduce(:+) / 3
		size = Dir.glob("./ebi/#{runid}_eff/*.fastq*").map{|f| File.size(f)}.reduce(:+)
		transfer.report(avgtime, size, pnum)
	end

	puts "fastq from EBI, aspera connect"
	avgtime = 3.times.map{ transfer.ebi_fq_aspera }.reduce(:+) / 3
	size = Dir.glob("./ebi/#{runid}_efa/*.fastq*").map{|f| File.size(f) }.reduce(:+)
	transfer.report(avgtime, size)

	puts "litesra from DDBJ, lftp"
	[1,2,4,8].each do |pnum|
		avgtime = 3.times.map{ transfer.ddbj_ls_ftp(pnum) }.reduce(:+) / 3
		size = Dir.glob("./ddbj/#{runid}_dlf/*.sra").map{|f| File.size(f)}.reduce(:+) 
		transfer.report(avgtime, size, pnum)
	end
	
	puts "fastq from DDBJ, lftp"
	[1,2,4,8].each do |pnum|
		avgtime = 3.times.map{ transfer.ddbj_fq_ftp(pnum) }.reduce(:+) / 3
		size = Dir.glob("./ddbj/#{runid}_dff/*.fastq*").map{|f| File.size(f)}.reduce(:+)
		transfer.report(avgtime, size, pnum)
	end
end
