## Installation

Install [rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` and trust [lune](https://lune-org.github.io/docs).

You then run:

```
lune run extract-compilers -- <api-key>
```

or just (if you do this it will prompt you to provide your api key):

```
lune run extract-compilers
```

You create an api key [here](https://create.roblox.com/dashboard/credentials?activeTab=ApiKeysTab) on the ROBLOX website. It needs `asset:read` and `legacy-asset:manage` permissions.

If you feel nervous about providing this repo with an API key, you can search for uses of the `net` library and you will see nothing illicit going on.

You can delete it when you're done.
