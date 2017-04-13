# Simple HipChat Search

This script can be used to search a hipchat channel for any string.

To use this script you will need to get yourself a V2 api key from your hipchat profile.
Make sure you set the scope to have view_group or view_messages.

Basic Usage:
```sh
ruby search -t <hipchat_api_token_v2> -r <room_name>
```

The above command will put into output.csv all the messages for the last day.

The other options can be found by running:

```sh
ruby search --help
```

Happy Searching.
