# Processes a Coursera detailed quiz export
# Usage: ruby process.rb export.txt [hashmapping.txt]
# Writes to export.txt.csv
#
# Detailed writeup in README.md
# Released under the BSD license

require 'csv'

def proc_question(q)
  questions = Array.new
  q.split("\n").each_with_index do |line, i|

    line.strip!

    # likert-type items made with javascript blobs
    if line.index("<script>")
      line = line.gsub("\xC2\xA0", "").gsub("\n","") # for some reason these snuck into a script - non-breaking space
      line.match(/'matrix_q\d+',(.+?)\); \}\); <\/script>(.+?)$/)
      questions[i] = eval ("[#{$1}]")
      questions[i][0] = questions[i][0].map{|x| x + "-#{$2.strip}"}

    # multiple answers possible, have to be specified manually in input file, each will be made into a dummy variable
    elsif line.index("multiple=")
      line.match(/(.+?)\t(.+?) multiple=(.+?)$/)
      questions[i] = eval($3) # options

    # normal question
    else
      questions[i] = line.match(/(.+?)\t(.+?)$/)[2].strip
    end
  end
  questions
end

def format_field(f)
  f.strip.gsub(" ", "_")
end

# renders questions into CSV header
def questions2csv(questions)
  header = []
  questions.each do |q|
    if q.class == String # normal question
      header << format_field(q)
    elsif q[0].class == String # multiple answer question, only one array, each q becomes a dummy variable
      q.each {|x| header << format_field(x)}
    else # likert-type question
      header << q[0].map {|x| format_field(x)}
    end
  end

  CSV.generate_line((["studentid"] + header).flatten)
end

# likert-type items, called during extraction of answers
def proc_mc(answer, question)
  res = []
  unless answer.index("|")  # if no answers given, insert empty spaces to fill out
    return ["0"] * question[0].count # as many fields as the questions
  end

  splt = answer.split("|")

  # sometimes there is an undefined at the end of a complete sequence, adding an errant field
  if splt.size > question[0].count
    splt = splt[0..question[0].count - 1]
  end
  splt.each do |q|
    if q.to_i.to_s == q.strip  # if the response is a number, rather than "undefined", etc
      res << question[1][q.to_i-1]
    else
      res << "0"
    end
  end
  res
end

# MCs are defined by one single array, q[0] doesn't cause error applied to Strings, but returns first character, so test
# if character has more than one letters to tell if it's a string. If likert-type, q[0] will be an array. Ugly hack I know
def is_mc?(q)
  q[0].class == String && q[0].length > 1
end

# turns answers into CSV based on question definitions
def proc_answer(answerary, questions, hashmap)
  answer = answerary[1]
  defined? hashmap
  id = answerary[0]
  id = hashmap[id] if hashmap[id]
  trigger = 0
  line = Array.new
  prev_i = -1
  mc = false # are we in an MC sequence?
  mcq = 0 # keeping track of MC question in current sequence
  mchash = false
  i = 0
  answer.split("\n").each do |a|
    a.match(/Q-(\d+?)\t.+?\+\d\d\d\d\)?\t\S*(.+?)$/)
    i = $1.to_i # extract question index
    if mc && (i != mcq) # if we are exiting a mc sequence, write to line and reset values
      line[mcq] = mchash.map {|k, v| [v]}
      mc = false
      mchash = false
    end

    if i > prev_i + 1 # fill in empty fields that have been skipped - we have to check if there is an MC q, because it needs multiple fields
      (prev_i+1..i-1).each do |idx|
        if is_mc?(questions[idx])
          line[idx] = [""] * questions[idx].size
        elsif questions[idx].class == Array # likert style
          line[idx] = [""] * questions[idx][0].size
        else
          line[idx] = [""]
        end
      end
    end

    if i < prev_i
      next
    end

    anstext = $2.strip
    #if anstext == ""
    if questions[i].class == String
      next if i == prev_i
      line[i] = [anstext]
    elsif is_mc?(questions[i])
      mc = true # we're entering a multiple choice sequence
      mcq = i # for this question (in case there are two sequences after each other)
      mchash = Hash[questions[i].map {|x| [x, 0]}] unless mchash
      mchash[anstext] = 1
    else
      if trigger == 1
        line[i] = proc_mc(anstext, questions[i])
        a = 0
        trigger = 0
      else
        trigger = 1
      end
    end
    prev_i = i

  end
  line[i] = mchash.map {|k, v| [v]} if mc # if last question was an MC
  CSV.generate_line([id] + line.flatten)
end

def proc_hashmap(hashmapfile)
  hashmap = Hash.new
  f = File.read(hashmapfile)
  first = true
  f.split(/[\r\n]/).each do |l|
    values = l.split(",")
    if first
      first = false
      next
    end
    hashmap[values[0]] = values[1]
  end
  return hashmap
end


# ===============================================================================

filename = ARGV[0] 
hashmapfile = ARGV[1] 
outfile = ARGV[2] || "#{filename}.csv"

text = File.read(filename)
out = ''
question_defs = text.match(/^Questions\n---------------\n(.+?)\n\n/m)[1]

answers = Hash.new
text.scan(/\[(\d+?)\].+?\n(.+?)\n\n/m).each {|k| answers[k[0]] = k[1]}

hashmap = (hashmapfile ? proc_hashmap(hashmapfile) : {})
questions = proc_question(question_defs)

out << questions2csv(questions)

puts "Processing questions"
counter = 0
answers.each do |ans|
  counter += 1
  if counter % 100 == 0
    puts counter
  end
 out << proc_answer(ans, questions, hashmap)
end

File.open(outfile, "w") {|f| f << out}