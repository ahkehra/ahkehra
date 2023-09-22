This is a simple, personal bootstrap script for [Termux](https://github.com/termux/termux-app/releases) to switch away from the boring BASH shell it comes with as the default.

## Requirements:
 - A device running Android 5.0 or above. (Recommended to have Android 7.0+ coz of [this](https://www.reddit.com/r/termux/comments/dnzdbs/end_of_android56_support_on_20200101/))
 - Termux app, __duh__. (Install from [F-Droid](https://f-droid.org/packages/com.termux/))

## Install:
Installing this is as easy as running the command below in Termux.
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/reallyakera/reallyakera/master/setup.sh)"
```

Don't worry, the existing `setup` will be backed up in your storage for later. You can find it in the `backup` directory at the location below.
> Internal Storage (`/sdcard` [or] `/storage/emulated/0`) -> `setup`
