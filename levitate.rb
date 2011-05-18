#! /usr/bin/env ruby

require 'rubygems'
require 'levenshtein'
require 'logger'
require 'terminal-table/import'
require 'commander/import'

program :name, 'Levitate: Levenshtein distance utility for CSV files.'
program :version, '0.1.0'
program :description, 'Find matches between strings in two CSV files using Levenshtein distances.'

command :compare do |c|
  c.syntax = './levitate.rb --file_a /pth/to/a.csv --file_b /pth/to/b.csv --match matchvar [--stratify stratvar1,stratvar2,etc --threshold 0.25]'
  c.option '--file_a String', String, 'Path to CSV file A'
  c.option '--file_b String', String, 'Path to CSV file B'
  c.option '--match STRING', String, 'Column name for matching'
  c.option '--stratify STRING', String, 'Optional column name(s) for stratification, separated with commas (no spaces)'
  c.option '--threshold FLOAT', Float, 'Threshold, between 0 and 1. 0 is perfect match.'
  c.option '--output STRING', String, 'Output type: pretty or csv'

  c.action do |args, options|
    # Error checking for options
    error = false

    csv = [] # Will store CSVs here...

    [options.file_a, options.file_b].each do |file|
      # Make sure files exist
      unless File.exist?(file)
        log "File #{file} not found."
        error = true
      end

      # Make sure we can read CSVs
      begin
        tmp = IO.read(file).split(/\r\n|\r|\n/).map{|line| line.split(/\s*,\s*/).map{|cell| cell.gsub('"', '')}}
        csv.push(tmp)
      rescue Exception => e
        log "Could not read CSV #{file}\n\n"
        log e.message
        error = true
      end
    end

    # Make sure a match var was provided
    unless options.match
      log = "You need to specify a match variable."
      error = true
    end

    break if error
    begin
      #pc = ProbComp.new(csv[0], csv[1], options.match, options.stratify.split[','], options.threshold)
      pc = ProbComp.new(csv[0], csv[1], options.match, options.stratify ? options.stratify.split(',') : [], options.threshold)

      if options.output && options.output.downcase == 'csv'
        puts pc.to_csv
      else
        puts pc
      end
    rescue Exception => e
      log "could not run command\n\n"
      log e.message
      log e.backtrace.inspect
    end
  end
end
default_command :compare

class ProbComp
  def initialize(csv1, csv2, match, stratify = nil, threshold = 0.25)
    @log = Logger.new(STDOUT)

    @a = csv1
    @b = csv2

    ([match] | (stratify ? stratify : [])).each do |var|
      raise "#{var} not in both datasets" unless @a[0].include?(var) && @b[0].include?(var)
    end

    @match_var = match
    @match_var_location = {:a => @a[0].index(@match_var), :b => @b[0].index(@match_var)}
    @stratify_vars = stratify
    @stratify_vars_location = {:a => @stratify_vars.map{|v| @a[0].index(v)}, :b => @stratify_vars.map{|v| @b[0].index(v)}}

    @threshold = threshold
    @comparisons = compare()
  end
  
  def to_csv
    headings = [@match_var+'(a)', @match_var+'(b)', 'DISTANCE', 'a/b', 'stratify'] | @a[0] | @b[0]
    loc_a = headings[5..headings.length].map{|h| @a[0].index(h)}
    loc_b = headings[5..headings.length].map{|h| @b[0].index(h)}

    out = headings.map{|h| "\"#{h}\""}.join(',')+"\n"
    
    @comparisons.each do |stratification, comparisons_hash|
      comparisons_hash.each do |str_a, results|
        out << ([str_a, '', results[:comparisons].length > 0 ? '' : "no matches < #{@threshold}", 'a', stratification] + loc_a.map{|loc| @a[results[:line]][loc] if loc}).map{|a| "\"#{a}\""}.join(',')+"\n"
        results[:comparisons].each_with_index do |result, i|
          out << ([str_a, result[0], (result[1] * 1000).round.to_f/1000, 'b', stratification] + loc_b.map{|loc| @b[result[2]][loc] if loc}).map{|a| "\"#{a}\""}.join(',')+"\n"
        end
      end
    end
    
    out
  end
      

  def to_s
    str = ""
    show_only = 10

    headings = ['*'+@match_var+'*', 'DISTANCE'] | @a[0].select{|a| a != @match_var && !@stratify_vars.include?(a) && @b[0].include?(a)}

    # Memoize the lookup for column locations
    loc_a = headings[2..headings.length].map{|h| @a[0].index(h)}
    loc_b = headings[2..headings.length].map{|h| @b[0].index(h)}


    @comparisons.each do |stratification, comparisons_hash|
      if stratification == ""
        str << "No stratification:\n"
      else
        str << "Stratification: #{stratification}\n"
      end

      comparisons_hash.each do |str_a, results|

        table = table do |t|
          t.headings = headings

          t << [str_a, results[:comparisons].length > 0 ? '' : "no matches < #{@threshold}"] + loc_a.map{|loc| @a[results[:line]][loc]}
          results[:comparisons].each_with_index do |result, i|
            break if i >= show_only
            t << [result[0], (result[1] * 1000).round.to_f/1000] + loc_b.map{|loc| @b[result[2]][loc]}
          end
        end
        str << table.to_s
        if results[:comparisons].length > show_only
          str << "and #{results[:comparisons].length - show_only} more\n\n"
        end
      end
    end

  return str
  end

  private
  def compare(threshold = 1)
    threshold = @threshold || threshold
    # output format: {'stratify_by' => {str_from_a => {:line => line_num, :comparisons => [[str_from_b, distance, line], [str_from_b2, distance2, line2], etc.]}}}

    comparisons = {}

    # Organize rows based on stratification
    # First load in everthing in @a based on stratification
    @a[1..@a.length].each_with_index do |line_a, i| # skip header row
      stratification_key = get_stratification_key(line_a, :a)
      compare_str = line_a[@match_var_location[:a]]

      # Initialization of data structures to hold comparisons
      # N.B. This will skip duplicates
      comparisons[stratification_key] = {} unless comparisons.has_key?(stratification_key)
      comparisons[stratification_key][compare_str] = {:line => i+1, :comparisons => []} # i+1 because we ignore header road
    end

    # Second, load all of @b into data structure based on stratification
    # We can do the comparison at the same time!
    @b[1..@b.length].each_with_index do |line_b, i|
      stratification_key = get_stratification_key(line_b, :b)
      next unless comparisons.has_key?(stratification_key)
      compare_str = line_b[@match_var_location[:b]]

      comparisons[stratification_key].each do |key, value|
        dist = Levenshtein::normalized_distance(key, compare_str)
        value[:comparisons].push([compare_str, dist, i+1]) if dist <= threshold # i+1 because we ignore header road
      end
    end

    # Third, sort the comparisons
    comparisons.each do |stratification, a|
      a.each do |str_a, hsh|
        hsh[:comparisons].sort!{|a, b| x = a[1] <=> b[1]; x == 0 ? a[0] <=> b[0] : x;}
      end
    end

    return comparisons
  end


  def get_stratification_key(line, which_file)
    key = ""
    @stratify_vars.each_with_index do |var,i|
      key << "#{var}=#{line[@stratify_vars_location[which_file][i]]};"
    end
    key
  end
end
