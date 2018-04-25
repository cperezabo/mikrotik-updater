# MikroTik Updater

Just a simple script to update a group of MikroTik devices automatically ✨

## How to use it? 🤔

You need to create a source file inside the `sources` folder and fill up the following variables:

* `private_key`: A private RSA key to be used to connect to the device. Before, you have to generate a public RSA key and import it into every device).
* `username`: The username linked to the imported public key.
* `hosts`: An array of the devices to be updated.

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

---

Additionally you can create a global alias for the updater

```bash
$ alias mikrotik-updater 'bash /path/to/updater.sh'
```

and execute it simply as

```bash
$ mikrotik-updater demo
```
