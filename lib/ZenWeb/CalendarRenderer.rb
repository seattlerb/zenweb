# this is a simple template. Globally replace Calendar with the name of
# your renderer and then go fill in YYY with the appropriate content.

require 'ZenWeb/GenericRenderer'
require 'date' # which requires rational
require 'time'

# class Integer
#   alias :slowgcd :gcd
#   def gcd(n)
#     m = abs
#     while n != 0
#       m %= n
#       tmp = m; m = n; n = tmp
#     end
#     m.abs
#   end
# end

# require 'tally'
# class Integer
#   tally :gcd, true
# end

=begin

= Class CalendarRenderer

DOC

=== Methods

=end

class CalendarRenderer < GenericRenderer

  DAYS_IN_MONTH = [
    [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
    [nil, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
  ]

=begin

     --- CalendarRenderer#render(content)

     DOC

=end

  def render(content)
    events = Hash.new { |h,k| h[k] = [] }
    reverse = false
    self.scan_region(content, /<cal/i, /<\/cal>/i) do |line, context|
      case context
      when :START then
        reverse = true if line =~ /<cal\s+reverse\s*>/i
      when :END then
        self.generate_calendars(events, reverse)
      else
        if line =~ /(\d\d\d\d-\d\d-\d\d):\s*(.*)/ then
          time, description = $1, $2
          raise "bad date: #{time}" unless Time.parse time
          events[$1] << description
        end
      end
    end

    return self.result
  end

  def generate_calendar(year, month, events)

    current_events = []

    date_start = Date.civil(year, month,  1)
    date_end   = Date.civil(year, month, -1)

    push "<table class=\"calendar\">"
    push "<tr>"
    push "<td valign=\"top\">" # calendar

    m2 = "%02d" % month
    push "<table class=\"view y#{year} m#{m2}\">\n"

    long_month_name = Date::MONTHNAMES[month]

    push "<tr class=\"title\">\n"
    push "<th colspan=7>#{long_month_name} #{year}</th>\n"
    push "</tr>\n"

    push "<tr class=\"weektitle\"\n"
    push Date::ABBR_DAYNAMES.map { |d| "<th class=\"#{d.downcase}\">#{d}</th>" }.join("\n")
    push "</tr>\n"

    dow_start = date_start.wday
    push "<tr class=\"days firstweek\">\n"
    push "<td colspan=#{dow_start}>&nbsp;</td>\n" unless dow_start == 0

    last_sunday = date_end.day - date_end.wday + 1

    week = 1
    wday = dow_start

    day_last = date_end.day

    1.upto(day_last) do |day|

      event=""
      cal = Time.local(year, month, day).strftime("%Y-%m-%d")
      if events.has_key? cal then
        current_events << "<li>#{cal}:\n<ul>\n"
        events[cal].each do |description|
          current_events << "<li>#{description}\n"
        end
        current_events << "</ul>\n"
        event=" event"
      end

      dow = Date::ABBR_DAYNAMES[(day + dow_start - 1) % 7].downcase
      d2 = "%02d" % day
      push "<td class=\"d#{d2} #{dow}#{event}\">#{day}</td>\n"

      if day != day_last and wday == 6 then
        push "</tr>\n"
        unless day == last_sunday then
          push "<tr class=\"days\">\n"
        else
          push "<tr class=\"days lastweek\">\n"
        end
        week += 1
      end
      
      wday += 1
      wday = 0 if wday >= 7 # remember 0..6
    end

    day_count = 7-date_end.wday-1
    push "<td colspan=#{day_count}>&nbsp;</td>\n" unless day_count == 0
    push "</tr>\n"
    push "</table>\n"
    push "</td>\n" # /calendar
    push "<td class=\"eventlist\">\n" # events
    push "<ul>\n"
    push current_events.join('')
    push "</ul>\n"
    push "</td>\n" # /events
    push "</tr>\n"
    push "</table>\n"
  end

  def generate_calendars(events, should_reverse=false)
    active_months = events.keys.map { |d| d[0..6] }.sort.uniq
    active_months = active_months.reverse if should_reverse
    active_months.each do |ym|
      year, month = ym.split(/-/).map { |n| n.to_i }
      self.generate_calendar(year, month, events)
    end
  end
end
