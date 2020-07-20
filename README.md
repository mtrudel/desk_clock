# Desk Clock

A Nerves-powered, NTP-synchronized, OLED-outputting desktop clock, running on a Raspberry Pi.
It was built as a demo for a [talk
given](https://github.com/mtrudel/talks/tree/master/2020-07-Toronto-Elixir-Night-Nerves.pdf) at the July 2020 Toronto Elixir Meetup, but is also
suitable for actual use.

Time is synchronized via NTP and display updates are adjusted to optimize the timeliness of the displayed time. In
typical operation, the displayed time should be no more than ~5ms out of sync with correct time.

## Building Hardware

Desk Clock runs on a Raspberry Pi and uses the following peripherals:

* An SSD1322 display configured and connected as suggested in the [SSD1322 library](https://github.com/mtrudel/ssd1322)
* A PEC11-style rotary encoder connected as per the
  [docs](https://github.com/mtrudel/desk_clock/blob/master/lib/desk_clock/rotary_encoder.ex#L11). See [here](https://github.com/mtrudel/rotary_breakout) for an easy to use breakout board suitable to purpose.

## Building the Application

Desk Clock is a standard nerves application, so it's best to consult their [excellent
docs](https://hexdocs.pm/nerves/getting-started.html) for the most up-to-date guide.

## Setting up Networking

Desk Clock uses VintageNet to configure networking. In the common case where you want to set up wifi, you'll want 
to ssh into the device and run a `VintageNet.configure` command as described in their
[README](https://github.com/nerves-networking/vintage_net_wifi). Settings made in such a way will be persistent.

## User Interface

The rotary encoder attached to Desk Clock performs the following tasks:

* When rotated, it cycles the top time display through the available timezones  
* When rotated while depressed, it cycles the bottom time display through the available timezones  
* When tapped, it toggles the display on and off
