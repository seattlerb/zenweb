# this is a simple template. Globally replace Calendar with the name of
# your renderer and then go fill in YYY with the appropriate content.

require 'ZenWeb/GenericRenderer'
require 'date'

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

    puts "calendarrenderer"
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
          description = $2
          date = Date.parse($1)
          events[date] << description
        end
      end
    end

    return self.result
  end

  def generate_calendar(year, month, events)

    current_events = []

    which_year = Date.leap?(year) ? 1 : 0
    date_start = Date.civil(year, month, 1)
    date_end   = Date.civil(year, month, DAYS_IN_MONTH[which_year][month])
    dow_start = date_start.wday

    push "<table width=\"100%\">"
    push "<tr>"
    push "<td width=\"50%\" valign=\"top\">" # calendar

    push "<table id=\"calendar\">\n"

    long_month_name = Date::MONTHNAMES[month]
    month_name = Date::ABBR_MONTHNAMES[month].downcase

    push "<tr id=\"title\">\n"
    push "<th colspan=7>#{long_month_name} #{year}</th>\n"
    push "</tr>\n"

    push "<tr id=\"weektitle\"\n"
    push Date::ABBR_DAYNAMES.map { |d| "<th class=\"#{d.downcase}\">#{d}</th>" }.join("\n")
    push "</tr>\n"

    push "<tr class=\"days\" id=\"firstweek\">\n"
    push "<td colspan=#{dow_start}>&nbsp;</td>\n" unless dow_start == 0

    last_sunday = date_end.day - date_end.wday + 1

    week = 1
    d=1
    wday = date_start.wday
    date_start.step(date_end, 1) do |day|

      event=""
      if events.has_key? day then
        current_events << "#{day}: #{events[day]}"
        event=" event"
      end

      klass = month_name
      dow = Date::ABBR_DAYNAMES[(d + dow_start - 1) % 7].downcase
      md = month_name.downcase + "%02d" % d
      push "<td class=\"#{klass} #{dow}#{event}\" id=\"#{md}\">#{d}</td>\n"

      if day.wday == 6 then
        push "</tr>\n"
        unless d == last_sunday then
          push "<tr class=\"days\">\n"
        else
          push "<tr class=\"days\" id=\"lastweek\">\n"
        end
        week += 1
      end

      d += 1
      wday += 1
      wday = 0 if wday >= 7 # remember 0..6
    end

    day_count = 7-date_end.wday-1
    push "<td colspan=#{day_count}>&nbsp;</td>\n" unless day_count == 0
    push "</tr>\n"
    push "</table>\n"
    push "</td>\n" # /calendar
    push "<td width=\"50%\" valign=\"top\">\n" # events
    push current_events.join("<br>\n")
    push "</td>\n" # /events
    push "</tr>\n"
    push "</table>\n"
  end

  def generate_calendars(events, should_reverse=false)
    active_months = events.keys.map { |d| [d.year, d.month] }.sort.uniq
    active_months = active_months.reverse if should_reverse
    active_months.each do |year, month|
      self.generate_calendar(year, month, events)
    end
  end
end
