# Libvirt Hook Controller

Libvirt Hook Controller is a little bash framework to manage different [libvirt hooks](https://libvirt.org/hooks.html) script. This framework has been designed to be minimal and try to follow KISS principle.

## Quickstart

Installation is as simple as this:
```
git clone https://github.com/mrjk/libvirt-hook-controller.git /etc/libvirt/hooks
```

You can now watch in your favorite log viewer what events are triggered. You may also
want to run custom scripts as well. Good, Libvirt Hook Controller comes also with configuration file(s) support. The config format is CSV. The configuration files must be in these locations:

* `conf/rules.conf`: Main
* `conf/rules.d/*.conf`:

The config merge algorithm to load the config is:
```
cat conf/rules.conf conf/rules.d/*.conf | sort -u
```

A rule file is a CSV format file with the following fields:

 * `hook`: The name of the hook to match. Can use `*`.
 * `operation`: The name of the operation to match. Can use `*`.
 * `object`: An exact name of object to filter. Recommanded to use `*`.
 * `priority`: A number between 0 and 99. Can use `*` to be set to 50.
 * `command`: Command to execute.

An acceptable good practice is to put all your hooks scripts in the [scripts](scripts/) directory, and fork this repository to keep track of your scripts.

## Information

This project has been brought to you by MrJK. Feel free to contribute, fork or improve this project. Contributions are welcome.

### License

[Source](https://opensource.org/licenses/MIT):

```
Copyright 2021 MrJK

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

