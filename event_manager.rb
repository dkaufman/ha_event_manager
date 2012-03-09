require 'csv'
require 'sunlight'
require 'date'

class EventManager
  INVALID_ZIPCODE = "00000"
  INVALID_PHONE_NUMBER = "0000000000"
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  def initialize(filename)
    puts "EventManager Initialized."
    @file = CSV.open(filename, {:headers => true, :header_converters => :symbol})
  end

  def print_names
    @file.each do |line|
      puts "#{line[:first_name]} #{line[:last_name]}"
    end
  end

  def print_numbers
    @file.each do |line|
      puts clean_number(line[:homephone])
    end
  end

  def print_zipcodes
    @file.each do |line|
      puts clean_zipcode(line[:zipcode])
    end
  end

  def output_data(filename)
    output = CSV.open(filename, "w")

    @file.each do |line|
      if @file.lineno == 2
        output << @file.headers
      end
        line[:homephone] = clean_number(line[:homephone])
        line[:zipcode] = clean_zipcode(line[:zipcode])
        output << line
    end
  end 

  def rep_lookup
    20.times do
      line = @file.readline
      legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))
      reps = legislators.collect do |leg|
        "#{leg.title}. #{leg.firstname[0]}. #{leg.lastname} (#{leg.party})"
      end

      puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{reps.join(", ")}"
    end
  end

  def create_form_letters
    letter = File.open('form_letter.html', 'r').read

    4.times do
      line = @file.readline
      custom_letter = letter.gsub("#first_name", line[:first_name])
      custom_letter = custom_letter.gsub("#last_name", line[:last_name])
      custom_letter = custom_letter.gsub("#street", line[:street])
      custom_letter = custom_letter.gsub("#city", line[:city])
      custom_letter = custom_letter.gsub("#state", line[:state])
      custom_letter = custom_letter.gsub("#zipcode", line[:zipcode])
      filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
      output = File.new(filename, "w")
      output.write(custom_letter)
    end
  end

  def rank_times
    hours = Array.new(24){0}

    @file.each do |line|
      hour = line[:regdate].split[1].split(":")[0]
      hours[hour.to_i] += 1
    end

    hours.each_with_index{|counter,hour| puts "#{hour}\t#{counter}"}
  end

  def day_stats
    days = Array.new(7){0}

    @file.each do |line|
      day = Date.strptime(line[:regdate], "%m/%d/%Y").wday
      days[day.to_i] += 1
    end

    days.each_with_index{|counter,day| puts "#{day}\t#{counter}"}
  end

  def state_stats
    state_data = {}

    @file.each do |line|
      state = line[:state]
      if state_data[state].nil?
        state_data[state] = 1
      else
        state_data[state] += 1
      end unless state.nil?
    end

    ranks = state_data.sort_by{ |state, counter| counter}.collect{|state, counter| state}.reverse
    state_data = state_data.sort_by{ |state, counter| state}

    state_data.each do |state, counter|
      puts "#{state}:\t#{counter}\t(#{ranks.index(state)+1})"
    end
  end

  def clean_number(number)
    number = remove_non_numbers(number)
    number = phone_to_ten_numbers(number)
  end

  def clean_zipcode(number)
    number = number.to_s
    number = remove_non_numbers(number)
    number = zip_to_five_numbers(number)
  end

  def remove_non_numbers(number)
    number = number.gsub(/[^\d]/, '') if number
  end

  def zip_to_five_numbers(number) 
    if (1..4).include?(number.length)
      "0"*(5-number.length) + number
    elsif number.length != 5
      INVALID_ZIPCODE
    else
      number
    end
  end

  def phone_to_ten_numbers(number)
    if number.length == 11 && number.start_with?("1")
      number[1..-1]
    elsif number.length != 10
      INVALID_PHONE_NUMBER
    else
      number
    end
  end

end

manager = EventManager.new("event_attendees.csv")
manager.state_stats