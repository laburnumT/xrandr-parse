# xrandr parser

A simple `bash` parser for `xrandr` output, that outputs to json.

It doesn't parse and output everything. It currently only does the things I'm
interested in. Which are:

- Name of the monitor
- If it is connected
- If it is the primary
- Its current config (resolution, offset, and refresh rate) if connected
- Possible modes for the monitor

## Dependencies

The only dependency (outside of `xrandr` and `bash`) is `jq`.
