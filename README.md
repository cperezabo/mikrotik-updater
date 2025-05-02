# MikroTik Updater

Just a simple script to update a group of MikroTik devices automatically ✨

## How to use it? 🤔

You need to create a source file inside the `sources` folder and fill up the following variables:

- `private_key`: The private RSA key used to connect to each device
- `username`: The username linked to the public RSA key.
- `hosts`: An array of the devices to be updated.

> You can find a `demo` file inside `sources` for a quickstart.

After having created the source file, simply execute the script 🤓

```bash
$ bash updater.sh demo
```

> It will look under the `sources` folder for a `demo` file

or you can specify an absolute path

```bash
$ bash updater.sh /path/to/sources/demo
```

You are done! 👍🏻

## Use it directly from GitHub

Create an alias so you always get the current version

Example:

```bash
$ alias mikrotik-updater 'curl -sL https://raw.githubusercontent.com/cperezabo/mikrotik-updater/refs/heads/master/updater.sh | bash -s --'
```

and execute it simply as

```bash
$ mikrotik-updater /path/to/sources/demo
```
