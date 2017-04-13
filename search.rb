# frozen_string_literal: true
require "hipchat"
require "pp"
require "JSON"
require "date"
require "time"
require "csv"
require "optparse"

# Wrapper
# Uses the room api:
# https://www.hipchat.com/docs/apiv2/method/view_room_history
# specifically the history method:
# https://github.com/hipchat/hipchat-rb/blob/bf25d66119888132313491fb2438433171ef883a/lib/hipchat/room.rb#L255
class HipchatSearch
  attr_accessor :messages, :client, :room, :result

  def initialize(token, room,
                 start_date: DateTime.now,
                 days_past: 1,
                 search_regexp: /.*/)
    self.room = room
    self.client = HipChat::Client.new(token, api_version: "v2")
    self.messages = []
    self.start_index = 0
    self.step = 1000
    self.start_date = start_date
    self.days_past = days_past
    self.search_regexp = search_regexp
  end

  def messages
    fetch_messages
    until @messages.empty?
      @messages.each do |message|
        yield OpenStruct.new(message) if search_regexp.match(message["message"])
      end
      self.start_index = start_index + step
      fetch_messages
    end
  end

  private

  attr_accessor :start_index, :step, :start_date, :days_past, :search_regexp

  def date_range
    (start_date...(start_date - days_past))
  end

  def fetch_messages
    self.result = JSON.parse(fetch_json)
    self.messages = result["items"]
  end

  def fetch_json
    client[room].history("max-results": step,
                         "start-index": start_index,
                         "date": date_range.first.iso8601,
                         "end-date": date_range.last.iso8601)
  end
end

options = { days_past: 1, search_regex: /.*/, file: "output.csv" }
OptionParser.new do |opts|
  opts.banner = "Usage: search.rb [options]"

  opts.on("-t", "--token TOKEN", "HipChat API v2 token") do |t|
    options[:token] = t
  end
  opts.on("-r", "--room ROOM", "Specify the ROOM name") do |r|
    options[:room] = r
  end
  opts.on("-d", "--days-past DAYS", "How many days to look back") do |d|
    options[:days_past] = d.to_i
  end
  opts.on("-s", "--search-regex STR", Regexp,
          "What are you looking for") do |s|
    options[:search_regex] = s
  end
  opts.on("-f", "--output-file FILE", "Where to output the results") do |f|
    options[:file] = f
  end
end.parse!

hipchat = HipchatSearch.new(options[:token],
                            options[:room],
                            days_past: options[:days_past],
                            search_regexp: options[:search_regex])

CSV.open(options[:file], "wb") do |csv|
  csv << %w(date message who)
  hipchat.messages do |message|
    csv << [DateTime.parse(message.date).strftime("%Y-%m-%d %H:%M:%S"),
            message.message,
            message.from["name"]]
  end
end
