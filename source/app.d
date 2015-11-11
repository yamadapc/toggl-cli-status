import core.thread;
import std.concurrency;
import std.conv;
import std.datetime;
import std.format;
import std.getopt;
import std.json;
import std.net.curl;
import std.process;
import std.stdio;

import colorize;

void main(string[] args) {
  string token;

  getopt(args,
    "t|token", &token
  );

  if(token == "") {
    token = environment.get("TOGGL_API_TOKEN", "");
  }

  TimeEntry te;
  TimeEntry te2;
  getCurrentTimeEntry(token, &te);

  auto tid = spawn(&updateDisplay, te);

  do {
    Thread.sleep(dur!"seconds"(2));
    try {
      getCurrentTimeEntry(token, &te2);
    } catch(Throwable err) {
      continue;
    }

    if(te2 != te) {
      te = te2;
      send(tid, te);
    }
  } while(true);
}

void updateDisplay(TimeEntry te) {
  auto oldLength = 0;
  auto running = true;
  auto on = true;
  auto onIndicator = " • ".color(fg.red);
  auto offIndicator = "   ";

  void onTimeEntry(TimeEntry _te) {
    te = _te;
  }

  void onOwnerTerminated(OwnerTerminated e) {
    running = false;
  }

  while(running) {
    // Block until there's a TE
    if(te == te.init) {
      write("\r                                        \r");
      stdout.flush();
      while(te == te.init) {
        receive(&onTimeEntry, &onOwnerTerminated);
      }
    }

    auto indicator = on ? onIndicator : offIndicator;
    write("\r                                          \r");
    cwrite(
      te.description.color(fg.light_black) ~
      indicator ~ te.humanDuration()
    );
    stdout.flush();
    on = !on;

    receiveTimeout(dur!"msecs"(500), &onTimeEntry, &onOwnerTerminated);
  }
}

struct TimeEntry {
  long id;
  SysTime start;
  string description;

  this(long id, string start, string description) {
    this.id = id;
    this.start = SysTime.fromISOExtString(start);
    this.description = description;
  }

  string humanDuration() {
    auto d = (Clock.currTime() - this.start)
      .split!("hours", "minutes", "seconds");

    auto shours = "%02d".format(d.hours);
    auto sminutes = "%02d".format(d.minutes);
    auto sseconds = "%02d".format(d.seconds);

    if(d.hours > 0) {
      shours = shours.color(mode.bold);
      sminutes = sminutes.color(fg.light_black);
      sseconds = sseconds.color(fg.light_black);
    } else if(d.minutes > 0) {
      sminutes = sminutes.color(mode.bold);
      shours = shours.color(fg.light_black);
      sseconds = sseconds.color(fg.light_black);
    } else {
      sseconds = sseconds.color(mode.bold);
      shours = shours.color(fg.light_black);
      sminutes = sminutes.color(fg.light_black);
    }

    auto sep = ":".color(fg.light_black);
    return format("%s" ~ sep ~ "%s" ~ sep ~ "%s", shours, sminutes, sseconds);
  }
}

void getCurrentTimeEntry(string token, TimeEntry* output) {
  auto client = HTTP();
  client.setAuthentication(token, "api_token");

  auto current = "https://www.toggl.com/api/v8/time_entries/current"
    .get(client)
    .parseJSON;

  auto te = current["data"];

  if(te.isNull) {
    *output = TimeEntry.init;
    return;
  }

  auto id = te["id"].integer();
  auto start = te["start"].str();
  auto description = te["description"].str();

  *output = TimeEntry(id, start, description);
}
